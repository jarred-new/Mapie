#include <QGuiApplication>
#include <QQmlContext>
#include <QQmlApplicationEngine>

#include "KmlManager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    KmlManager kmlManager;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("kmlManager", &kmlManager);
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("Mapie", "Main");

    return QGuiApplication::exec();
}
