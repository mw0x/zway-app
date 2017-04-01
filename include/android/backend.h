
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

#ifndef ZWAY_ANDROID_BACKEND_H_
#define ZWAY_ANDROID_BACKEND_H_

#include "backendbase.h"

// ============================================================ //

/**
 * @brief The Backend class
 */

class Backend : public BackendBase
{
    Q_OBJECT

public:

    Backend(QGuiApplication *app, QQmlEngine *engine);


    bool start(const QString &host, uint16_t port=ZWAY_PORT);


    void onEvent(CLIENT client, EVENT event);


    Q_INVOKABLE bool init();

    Q_INVOKABLE void unlockStore(const QString &filename, const QString &password, const QJSValue &callback = QJSValue());

    Q_INVOKABLE bool setConfig(const QJsonObject &config, const QJSValue &callback = QJSValue());



    Q_INVOKABLE void sendToBack();


    Q_INVOKABLE bool checkPhoneContacts(const QJSValue &callback = QJSValue());


    Q_INVOKABLE QString formatPhoneNumber(const QString& input);

    Q_INVOKABLE QString clientPhoneNumber();


    Q_INVOKABLE qint32 processCapturedImage(const QString &url);


    bool prepareStore();


    bool readPhoneContacts(QJsonObject &res);

    bool readPhoneContactsHex(QMap<QString,QString>& res);


    Client::Status clientStatus();

private slots:

    void onNativeCallback(qint32 id, const QJsonObject &data);

private:

    QString m_fcmToken;

};

// ============================================================ //

#endif
