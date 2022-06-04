/*
 * Copyright (C) 2022  walking-octopus
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * chromecaster-ut is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <QGuiApplication>
#include <QCoreApplication>
#include <QUrl>
#include <QString>
#include <QQuickView>
#include <QProcess>
#include <QObject>
#include <QQmlContext>

int main(int argc, char *argv[])
{
    QGuiApplication *app = new QGuiApplication(argc, (char**)argv);
    app->setApplicationName("chromecaster-ut.walking-octopus");

    qDebug() << "Loading the QML...";
    QQuickView *view = new QQuickView();
    view->rootContext()->setContextProperty("serverReady", QVariant(false));
    view->setSource(QUrl("qrc:/Main.qml"));
    view->setResizeMode(QQuickView::SizeRootObjectToView);

    // QProcess Initialization
    QProcess internalServer;
    internalServer.setWorkingDirectory("./go-chromecast");
    internalServer.setProcessChannelMode(QProcess::MergedChannels);

    // Start the internal server
    qDebug() << "Starting the internal server...";
    internalServer.start("./go-chromecast", QStringList() << "httpserver");

    // Error handeling
    if (!internalServer.waitForStarted()) {
        qDebug() << "Error starting internal server: " << internalServer.errorString();
        qDebug() << internalServer.exitCode();

        return 1;
    }
    // FIXME: Use an exit code 1.
    QObject::connect(&internalServer, SIGNAL(finished(int)), app, SLOT(quit()));

    // Debug messages and standard output/error.
    QObject::connect(&internalServer, &QProcess::started, []() {
        qDebug() << "Internal server started!";
    });

    QObject::connect(&internalServer, &QProcess::readyRead, [&internalServer, &view]() {
        QString output = internalServer.readAll().trimmed();
        qDebug().noquote() << "Server: " << output;

        if (output.contains("starting http server")) {
            qDebug() << "Internal server is ready.";

            // Signal to the QML that the server is ready.
            view->rootContext()->setContextProperty("serverReady", QVariant(true));
        }
    });

    qDebug() << "Entering the main loop...";
    view->show();
    return app->exec();
}
