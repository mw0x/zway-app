
// ============================================================ //
//
//   d88888D db   d8b   db  .d8b.  db    db
//   YP  d8' 88   I8I   88 d8' `8b `8b  d8'
//      d8'  88   I8I   88 88ooo88  `8bd8'
//     d8'   Y8   I8I   88 88~~~88    88
//    d8' db `8b d8'8b d8' 88   88    88
//   d88888P  `8b8' `8d8'  YP   YP    YP
//
//   open-source, cross-platform, crypto-messenger
//
//   Copyright (C) 2017 Marc Weiler
//
//   This program is free software: you can redistribute it and/or modify
//   it under the terms of the GNU General Public License as published by
//   the Free Software Foundation, either version 3 of the License, or
//   (at your option) any later version.
//
//   This program is distributed in the hope that it will be useful,
//   but WITHOUT ANY WARRANTY; without even the implied warranty of
//   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//   GNU General Public License for more details.
//
//   You should have received a copy of the GNU General Public License
//   along with this program. If not, see <http://www.gnu.org/licenses/>.
//
// ============================================================ //

#include <QGuiApplication>
#include <QQmlApplicationEngine>

#if (defined Q_OS_LINUX && !defined Q_OS_ANDROID) || defined Q_OS_WIN
#define STATIC_BUILD
#include <QQmlExtensionPlugin>
//Q_IMPORT_PLUGIN(QWindowsIntegrationPlugin)
Q_IMPORT_PLUGIN(QtQuick2Plugin)
Q_IMPORT_PLUGIN(QtQuick2WindowPlugin)
Q_IMPORT_PLUGIN(QtQuickLayoutsPlugin)
//Q_IMPORT_PLUGIN(QMultimediaDeclarativeModule)
#endif

#if defined Q_OS_WIN
#include <windows.h>
#include <dbghelp.h>
#endif

#if defined Q_OS_ANDROID
#include "android/hooks.h"
#else
#include "desktop/backend.h"
#endif

// ============================================================ //

int main(int argc, char *argv[])
{

#if !defined Q_OS_ANDROID && !defined Q_OS_OSX && !defined Q_OS_IOS

    /*
    if (!SecMem::setup(8192)) {

        return -1;
    }
    */

#endif

    if (!Crypto::setup()) {

        return -1;
    }

    QGuiApplication app(argc, argv); QQmlApplicationEngine engine;

#if defined STATIC_BUILD

    qobject_cast<QQmlExtensionPlugin*>(qt_static_plugin_QtQuick2Plugin().instance())->registerTypes("QtQuick");
    qobject_cast<QQmlExtensionPlugin*>(qt_static_plugin_QtQuick2WindowPlugin().instance())->registerTypes("QtQuick.Window");
    qobject_cast<QQmlExtensionPlugin*>(qt_static_plugin_QtQuickLayoutsPlugin().instance())->registerTypes("QtQuick.Layouts");
  //qobject_cast<QQmlExtensionPlugin*>(qt_static_plugin_QMultimediaDeclarativeModule().instance())->registerTypes("QtMultimedia");

    engine.setImportPathList(QStringList());

#endif

    std::shared_ptr<Backend> backend(new Backend(&app, &engine));

    if (!backend->start( /* "192.168.178.23" */ "185.11.138.96" )) {

        return -1;
    }

    engine.load(QUrl(QStringLiteral("qrc:///qml/main.qml")));

    int ret = app.exec();

    backend->close();

    backend.reset();

#if !defined Q_OS_ANDROID && !defined Q_OS_OSX && !defined Q_OS_IOS

    //SecMem::cleanup();

#endif

    return ret;
}

// ============================================================ //
