#include "plantidentifier.h"
#include <QFile>
#include <QFileInfo>
#include <QHttpMultiPart>
#include <QHttpPart>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>
#include <QDebug>
#include <QMimeDatabase>
#include <QStandardPaths>
#include <QDir>
#include <QImage>
#include <QSslSocket>
#include <QSslError>

PlantIdentifier::PlantIdentifier(QObject *parent)
    : QObject(parent)
    , m_manager(new QNetworkAccessManager(this))
{
    connect(m_manager, &QNetworkAccessManager::finished,
            this, &PlantIdentifier::onReplyFinished);
}

QString PlantIdentifier::saveImageToTemp(const QVariant &imageVariant)
{
    QImage image = imageVariant.value<QImage>();
    if (image.isNull()) {
        qWarning() << "saveImageToTemp: QImage 为空";
        return "";
    }

    QString tempDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    QDir().mkpath(tempDir);
    QString tempPath = tempDir + "/captured_preview.jpg";

    if (image.save(tempPath, "JPEG", 90)) {
        qDebug() << "预览图已保存:" << tempPath;
        return QUrl::fromLocalFile(tempPath).toString();
    } else {
        qWarning() << "预览图保存失败";
        return "";
    }
}

void PlantIdentifier::identifyImage(const QString &imagePath)
{
    qDebug() << "identifyImage 路径:" << imagePath;

    // 先检查 SSL 是否可用
    if (!QSslSocket::supportsSsl()) {
        qWarning() << "SSL 不可用！无法发起 HTTPS 请求";
        qWarning() << "SSL 构建版本:" << QSslSocket::sslLibraryBuildVersionString();
        qWarning() << "SSL 运行版本:" << QSslSocket::sslLibraryVersionString();
        emit identifyError(
            "SSL/TLS 不可用，无法连接服务器。\n"
            "请在 Qt Maintenance Tool 中安装 OpenSSL 组件，\n"
            "或检查 CMakeLists.txt 中的 OpenSSL 配置。\n\n"
            "构建版本: " + QSslSocket::sslLibraryBuildVersionString()
            );
        return;
    }

    QString filePath = imagePath;
    if (filePath.startsWith("file://")) {
        filePath = QUrl(filePath).toLocalFile();
    }

    if (!QFile::exists(filePath)) {
        qWarning() << "图片不存在:" << filePath;
        emit identifyError("图片文件不存在: " + filePath);
        return;
    }

    qDebug() << "文件存在, 大小:" << QFileInfo(filePath).size() << "字节";
    sendRequest(filePath);
}

void PlantIdentifier::sendRequest(const QString &filePath)
{
    if (m_busy) {
        qDebug() << "正在识别中";
        return;
    }

    m_busy = true;
    emit busyChanged();

    qDebug() << "上传到 Pl@ntNet:" << filePath;

    QUrl url(API_URL);
    QUrlQuery query;
    query.addQueryItem("include-related-images", "false");
    query.addQueryItem("no-reject", "false");
    query.addQueryItem("nb-results", "5");
    query.addQueryItem("lang", "zh");
    query.addQueryItem("api-key", API_KEY);
    url.setQuery(query);

    QHttpMultiPart *multiPart = new QHttpMultiPart(QHttpMultiPart::FormDataType);

    // 图片部分
    QHttpPart imagePart;
    imagePart.setHeader(QNetworkRequest::ContentDispositionHeader,
                        QVariant("form-data; name=\"images\"; filename=\"photo.jpg\""));

    QMimeDatabase mimeDb;
    QString mimeType = mimeDb.mimeTypeForFile(filePath).name();
    if (mimeType.isEmpty()) mimeType = "image/jpeg";
    imagePart.setHeader(QNetworkRequest::ContentTypeHeader, QVariant(mimeType));

    QFile *file = new QFile(filePath);
    if (!file->open(QIODevice::ReadOnly)) {
        qWarning() << "无法打开文件:" << filePath;
        emit identifyError("无法打开图片文件");
        m_busy = false;
        emit busyChanged();
        delete file;
        delete multiPart;
        return;
    }

    imagePart.setBodyDevice(file);
    file->setParent(multiPart);
    multiPart->append(imagePart);

    // organs 参数
    QHttpPart organPart;
    organPart.setHeader(QNetworkRequest::ContentDispositionHeader,
                        QVariant("form-data; name=\"organs\""));
    organPart.setBody("auto");
    multiPart->append(organPart);

    QNetworkRequest request(url);

    qDebug() << "POST:" << url.toString();

    QNetworkReply *reply = m_manager->post(request, multiPart);
    multiPart->setParent(reply);

    // 监听 SSL 错误（便于调试）
    connect(reply, &QNetworkReply::sslErrors,
            this, [](const QList<QSslError> &errors) {
                for (const QSslError &err : errors) {
                    qWarning() << "SSL 错误:" << err.errorString();
                }
            });
}

void PlantIdentifier::onReplyFinished(QNetworkReply *reply)
{
    m_busy = false;
    emit busyChanged();

    int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    qDebug() << "API 状态码:" << httpStatus;

    if (reply->error() != QNetworkReply::NoError) {
        QString errorMsg = reply->errorString();
        QByteArray responseData = reply->readAll();
        qWarning() << "API 错误:" << httpStatus << errorMsg;
        qDebug() << "响应体:" << responseData;

        if (httpStatus == 401) {
            emit identifyError("API Key 无效，请检查 Pl@ntNet API Key");
        } else if (httpStatus == 404) {
            emit identifyError("无法识别该植物，请拍摄叶片或花朵");
        } else if (httpStatus == 429) {
            emit identifyError("API 调用次数已达上限，请稍后再试");
        } else {
            emit identifyError("网络错误: " + errorMsg);
        }

        reply->deleteLater();
        return;
    }

    QByteArray data = reply->readAll();
    qDebug() << "返回数据长度:" << data.size();
    parseResponse(data);
    reply->deleteLater();
}

void PlantIdentifier::parseResponse(const QByteArray &data)
{
    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(data, &parseError);

    if (parseError.error != QJsonParseError::NoError) {
        qWarning() << "JSON 解析错误:" << parseError.errorString();
        emit identifyError("服务器返回数据格式错误");
        return;
    }

    QJsonObject root = doc.object();
    QJsonArray results = root["results"].toArray();

    if (results.isEmpty()) {
        emit identifyError("未能识别该植物，请对准叶片或花朵重新拍摄");
        return;
    }

    QJsonObject first = results[0].toObject();
    double score = first["score"].toDouble();
    QJsonObject species = first["species"].toObject();

    QString scientificName = species["scientificNameWithoutAuthor"].toString();

    QJsonArray commonNames = species["commonNames"].toArray();
    QString chineseName;
    for (const QJsonValue &v : commonNames) {
        chineseName = v.toString();
        break;
    }

    QString familyName = species["family"].toObject()["scientificName"].toString();
    QString genusName = species["genus"].toObject()["scientificName"].toString();

    QString displayName;
    if (!chineseName.isEmpty()) {
        displayName = chineseName + " (" + scientificName + ")";
    } else {
        displayName = scientificName;
    }

    QString detail;
    detail += QString("学名: %1\n").arg(scientificName);
    if (!chineseName.isEmpty())
        detail += QString("中文名: %1\n").arg(chineseName);
    if (!familyName.isEmpty())
        detail += QString("科: %1\n").arg(familyName);
    if (!genusName.isEmpty())
        detail += QString("属: %1\n").arg(genusName);
    detail += QString("置信度: %1%\n").arg(QString::number(score * 100, 'f', 1));

    if (results.size() > 1) {
        detail += "\n--- 其他可能 ---\n";
        int count = qMin(results.size(), 4);
        for (int i = 1; i < count; i++) {
            QJsonObject alt = results[i].toObject();
            double altScore = alt["score"].toDouble();
            QJsonObject altSp = alt["species"].toObject();
            QString altSci = altSp["scientificNameWithoutAuthor"].toString();

            QJsonArray altNames = altSp["commonNames"].toArray();
            QString altCn;
            if (!altNames.isEmpty()) altCn = altNames[0].toString();

            if (!altCn.isEmpty()) {
                detail += QString("%1. %2 (%3) - %4%\n")
                .arg(i).arg(altCn).arg(altSci)
                    .arg(QString::number(altScore * 100, 'f', 1));
            } else {
                detail += QString("%1. %2 - %3%\n")
                .arg(i).arg(altSci)
                    .arg(QString::number(altScore * 100, 'f', 1));
            }
        }
    }

    qDebug() << "识别成功:" << displayName;
    emit identifyResult(displayName, detail, score);
}