#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QDebug>
#include <QSslSocket>
#include <QDir>
#include <QCoreApplication>

#include "plantidentifier.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // ========================================
    // SSL 诊断信息
    // ========================================
    qDebug() << "===== SSL 诊断 =====";
    qDebug() << "SSL 库构建版本:" << QSslSocket::sslLibraryBuildVersionString();
    qDebug() << "SSL 库运行版本:" << QSslSocket::sslLibraryVersionString();
    qDebug() << "SSL 是否可用:" << QSslSocket::supportsSsl();
    qDebug() << "应用程序路径:" << QCoreApplication::applicationDirPath();

    // 在 Android 上，尝试列出应用 lib 目录中的 so 文件
    QDir libDir(QCoreApplication::applicationDirPath());
    qDebug() << "lib 目录内容:";
    for (const QString &entry : libDir.entryList(QStringList() << "*.so", QDir::Files)) {
        if (entry.contains("ssl") || entry.contains("crypto") || entry.contains("SSL")) {
            qDebug() << "  找到:" << entry;
        }
    }
    qDebug() << "===== SSL 诊断结束 =====";

    QQuickStyle::setStyle("Material");

    // 注册 PlantIdentifier 单例
    PlantIdentifier *identifier = new PlantIdentifier(&app);
    qmlRegisterSingletonInstance("NatureVision", 1, 0, "PlantAPI", identifier);

    QQmlApplicationEngine engine;

    const QUrl url(u"qrc:/qt/qml/NatureVision/Main.qml"_qs);
    qDebug() << "加载 QML:" << url;

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() {
            qCritical() << "QML 对象创建失败！";
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection
        );

    engine.load(url);

    return app.exec();
}