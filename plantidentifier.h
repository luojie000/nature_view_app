#ifndef PLANTIDENTIFIER_H
#define PLANTIDENTIFIER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QString>
#include <QUrl>
#include <QImage>

class PlantIdentifier : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

public:
    explicit PlantIdentifier(QObject *parent = nullptr);

    bool busy() const { return m_busy; }

    // QML 可调用：传入图片本地文件路径
    Q_INVOKABLE void identifyImage(const QString &imagePath);

    // QML 可调用：将 QImage 保存为临时文件并返回路径
    // 用于解决 onImageCaptured 返回 QImage 无法直接显示的问题
    Q_INVOKABLE QString saveImageToTemp(const QVariant &imageVariant);

signals:
    void identifyResult(const QString &name, const QString &detail, double score);
    void identifyError(const QString &errorMessage);
    void busyChanged();

private slots:
    void onReplyFinished(QNetworkReply *reply);

private:
    void sendRequest(const QString &filePath);
    void parseResponse(const QByteArray &data);

    QNetworkAccessManager *m_manager;
    bool m_busy = false;

    const QString API_KEY = "2b10tsNajXMyBCpzckLNP5XfoO";
    const QString API_URL = "https://my-api.plantnet.org/v2/identify/all";
};

#endif // PLANTIDENTIFIER_H