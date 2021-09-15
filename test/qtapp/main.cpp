#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "nimstatus.hpp"

extern "C"
{
#include "statuslib.h"
}

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    NimMain();  // Should be called always to initialize nim runtime


    helloWorld(); // Example invocation of a nim function

    auto someDirName = QString{"./test"}.toLocal8Bit().data();
    ensureDirectories(someDirName, someDirName, someDirName);

    QString fleetStr{"{\"fleets\":{\"eth.prod\":{\"boot\":{\"boot-01.ac-cn-hongkong-c.eth.prod\":\"enode://6e6554fb3034b211398fcd0f0082cbb6bd13619e1a7e76ba66e1809aaa0c5f1ac53c9ae79cf2fd4a7bacb10d12010899b370c75fed19b991d9c0cdd02891abad@47.75.99.169:443\"},\"mail\":{\"mail-01.ac-cn-hongkong-c.eth.prod\":\"enode://606ae04a71e5db868a722c77a21c8244ae38f1bd6e81687cc6cfe88a3063fa1c245692232f64f45bd5408fed5133eab8ed78049332b04f9c110eac7f71c1b429@47.75.247.214:443\"},\"rendezvous\":{\"boot-01.ac-cn-hongkong-c.eth.prod\":\"/ip4/47.75.99.169/tcp/30703/ethv4/16Uiu2HAmV8Hq9e3zm9TMVP4zrVHo3BjqW5D6bDVV6VQntQd687e4\"},\"whisper\":{\"node-01.ac-cn-hongkong-c.eth.prod\":\"enode://b957e51f41e4abab8382e1ea7229e88c6e18f34672694c6eae389eac22dab8655622bbd4a08192c321416b9becffaab11c8e2b7a5d0813b922aa128b82990dab@47.75.222.178:443\"}}},\"meta\":{\"hostname\":\"node-01.do-ams3.proxy.misc\",\"timestamp\":\"2021-09-09T00:00:14.760436\"}}"};
   
    NimStatus statusObj(fleetStr);

    statusObj.initializeNode("./test", "./test");

    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl)
        {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
