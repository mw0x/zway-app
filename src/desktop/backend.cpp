
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

#include <QJsonObject>
#include <QJsonArray>
#include <QDir>
#include <QRegularExpression>

#include "desktop/backend.h"

#include <Zway/event/eventhandler.h>
#include <Zway/store.h>

// ============================================================ //

/**
 * @brief Backend::Backend
 * @param app
 * @param engine
 */

Backend::Backend(QGuiApplication *app, QQmlEngine *engine)
    : BackendBase(app, engine)
{

}

/**
 * @brief Backend::start
 * @param host
 * @param port
 * @return
 */

bool Backend::start(const QString &host, uint16_t port)
{
    if (!BackendBase::start(host, port, std::bind(&Backend::onEvent, this, std::placeholders::_1, std::placeholders::_2))) {

        return false;
    }

    return true;
}

/**
 * @brief Backend::onEvent
 * @param event
 */

void Backend::onEvent(Client$ client, Event$ event)
{
    switch (event->type()) {
    default:

        BackendBase::onEvent(client, event);

        break;
    }
}

/**
 * @brief Backend::init
 * @return
 */

bool Backend::init()
{
    if (!prepareStore()) {

        return false;
    }

    return true;
}

/**
 * @brief Backend::handleClose
 * @return
 */

bool Backend::handleClose()
{
    if (status() >= Authenticated) {

        return false;
    }

    return true;
}

/**
 * @brief Backend::unlockStore
 * @param filename
 * @param password
 * @param callback
 */

void Backend::unlockStore(const QString &filename, const QString &password, const QJSValue &callback)
{
    Store$ store = Store::unlock(filename.toStdString(), password.toStdString(), true);

    if (!store) {

        emit invokeCallback(
                callback, {
                    ubjToJson(ERROR_UBJ("Failed to unlock store!")) });
    }
    else {

        setStore(store);

        emit storeUnlocked();

        emit invokeCallback(callback);
    }
}

/**
 * @brief Backend::prepareStore
 * @return
 */

bool Backend::prepareStore()
{

#if defined Q_OS_LINUX || defined Q_OS_OSX

    QString storeDir = QDir::homePath() + "/.Zway";

#endif

    QDir dir(storeDir);

    if (!dir.exists()) {

        dir.mkpath(storeDir);

        dir.cd(storeDir);
    }

    m_storeDir = dir.absolutePath();


    QString stores;

    QStringList filter;

    filter.append(QStringLiteral("*.store"));

    QFileInfoList list = dir.entryInfoList(filter);

    if (list.size() == 1 && list[0].isFile()) {

        stores = list[0].absoluteFilePath();
    }
    else
    if (list.size() > 1) {

        for (auto &info : list) {

            if (info.isFile()) {

                if (stores.size()) {

                    stores += ";";
                }

                stores += info.absoluteFilePath();
            }
        }
    }


    emit ready(false, stores, QString());


    return true;
}

// ============================================================ //
