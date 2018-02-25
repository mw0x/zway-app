
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
//   Copyright (C) 2018 Marc Weiler
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

#include <QQmlContext>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDir>
#include <QRegularExpression>
#include <QAndroidJniObject>

#include "android/backend.h"

#include <Zway/event/eventhandler.h>

// ============================================================ //

/**
 * @brief Backend::Backend
 * @param app
 * @param engine
 */

Backend::Backend(QGuiApplication *app, QQmlEngine *engine)
    : BackendBase(app, engine)
{
    QQmlContext* context = m_engine->rootContext();

    qint32 statusBarHeight = QAndroidJniObject::callStaticMethod<qint32>(
                "de.atomicode.zway.ZwayActivity",
                "getStatusBarHeight");

    context->setContextProperty(QStringLiteral("statusBarHeight"), statusBarHeight);

    // connect some signals

    QObject::connect(this, &Backend::nativeCallback, this, &Backend::onNativeCallback);
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

void Backend::onEvent(CLIENT client, EVENT event)
{
    switch (event->type()) {
    case Event::ContactRequest: {

        if (!m_active) {

            std::string name = event->data()["name"].toStr();

            QJsonObject data = {
                {"ticker", ""},
                {"title" , QString("Contact request from %0").arg(QString::fromStdString(name))},
                {"text"  , ""}
            };

            QAndroidJniObject::callStaticMethod<void>(
                    "de.atomicode.zway.ZwayActivity",
                    "showNotification",
                    "(ILjava/lang/String;)V",
                    1,
                    QAndroidJniObject::fromString(
                            QJsonDocument(data).toJson(QJsonDocument::Compact)).object<jstring>());
        }

        emit contactRequest(ubjToJsonObj(event->data()));

        break;
    }
    case Event::MessageIncoming: {

        UBJ::Object message = event->data()["message"];

        if (!m_active) {

            UBJ::Object contact;

            store()->query("contacts", UBJ_OBJ("id" << message["src"]), &contact, {}, UBJ_ARR("name"));

            QJsonObject data = {
                {"ticker", ""},
                {"title" , QString("Message from %0").arg(contact["name"].toStr().c_str())},
                {"text"  , ""},
                {"src"   , message["src"].toInt()}
            };

            QAndroidJniObject::callStaticMethod<void>(
                    "de.atomicode.zway.ZwayActivity",
                    "showNotification",
                    "(ILjava/lang/String;)V",
                    1,
                    QAndroidJniObject::fromString(
                            QJsonDocument(data).toJson(QJsonDocument::Compact)).object<jstring>());

        }

        emit messageIncoming(ubjToJsonObj(message));

        break;
    }
    case Event::ResourceReceived: {

        UBJ::Object message = event->data()["message"];

        UBJ::Object resource = event->data()["resource"];

        processResourceRecv(message, resource);

        emit resourceReceived(ubjToJsonObj(message), ubjToJsonObj(resource));

        break;
    }
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
    QAndroidJniObject::callStaticMethod<void>(
                "de.atomicode.zway.ZwayActivity",
                "nativeInit");

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
    STORE store = Store::unlock(filename.toStdString(), password.toStdString(), true);

    if (!store) {

        emit invokeCallback(
                callback, {
                    ubjToJson(ERROR_UBJ("Failed to unlock store!")) });
    }
    else {


        UBJ::Object config;

        store->getConfig(config);

        config["fcmToken"] = m_fcmToken.toStdString();

        store->setConfig(config);


        setStore(store);

        emit storeUnlocked();

        emit invokeCallback(callback);
    }
}

/**
 * @brief Backend::setConfig
 * @param config
 * @param callback
 * @return
 */

bool Backend::setConfig(const QJsonObject &config, const QJSValue &callback)
{
    if (!BackendBase::setConfig(config, callback)) {

        return false;
    }

    return true;
}

/**
 * @brief Backend::sendToBack
 */

void Backend::sendToBack()
{
    QAndroidJniObject::callStaticMethod<void>(
                "de.atomicode.zway.ZwayActivity",
                "sendToBack");
}

/**
 * @brief Backend::checkPhoneContacts
 * @param callback
 * @return
 */

bool Backend::checkPhoneContacts(const QJSValue &callback)
{
    /*
    UBJ::Array arr;

    QMap<QString,QString> map;

    if (readPhoneContactsHex(map)) {

        for (auto it = map.begin(); it != map.end(); ++it) {

            arr.push(it.key().toStdString());
        }
    }

    if (arr.size()) {

        findContact(

                UBJ_OBJ("numbers" << arr),

                [this, map, callback] (EVENT event) {

                    UBJ::Value results = event->data()["results"];

                    if (results.size()) {

                        for (auto &it : results) {

                            UBJ::Value &val = it.second;

                            std::string name = val["name"].toStr();

                            std::string phone = val["phone"].toStr();

                            QString name = map[phone.c_str()];

                            / *
                            m_store->addContact(
                                    UBJ_OBJ(
                                        "name"   << name <<
                                        "phone"  << phone <<
                                        "label2" << name.toStdString()));* /
                        }
                    }

                    emit invokeCallback(callback);
                });
    }
    */

    return true;
}

/**
 * @brief Backend::formatPhoneNumber
 * @param input
 * @return
 */

QString Backend::formatPhoneNumber(const QString &input)
{
    QString number;

    QRegularExpressionMatch match = QRegularExpression("^\\s*(\\+)?(0)?([\\d\\s-\\(\\)]+)$").match(input);

    if (match.hasMatch()) {

        QString countryCode = "49";

        if (match.capturedLength(1) == 0 &&
            match.capturedLength(2) == 1) {

            number = "+" + countryCode + match.captured(3).replace(QRegularExpression("[^0-9]"), QString());
        }
        else
        if (match.capturedLength(1) == 1 &&
            match.capturedLength(2) == 0) {

            number = "+" + match.captured(3).replace(QRegularExpression("[^0-9]"), QString());
        }
    }

    return number;
}

/**
 * @brief Backend::clientPhoneNumber
 * @return
 */

QString Backend::clientPhoneNumber()
{
    QString res;

    QAndroidJniObject obj = QAndroidJniObject::callStaticObjectMethod(
            "de.atomicode.zway.ZwayActivity",
            "getPhoneNumber",
            "()Ljava/lang/String;");

    res = obj.toString();

    return res;
}

/**
 * @brief Backend::processCapturedImage
 * @param url
 * @return
 */

qint32 Backend::processCapturedImage(const QString &url)
{
    Q_UNUSED(url)

    /*
    QQuickImageProvider* provider = (QQuickImageProvider*)getEngine()->imageProvider(QStringLiteral("camera"));

    if (provider) {

        QSize size, requestedSize;

        QImage img = provider->requestImage(url, &size, requestedSize);

        if (!img.isNull()) {

            QByteArray data;
            QBuffer buf(&data);

            buf.open(QIODevice::WriteOnly);

            img.save(&buf, "JPG");

            buf.close();

            RESOURCE res = Resource::createFromData(url.toStdString(), (uint8_t*)data.constData(), data.size(), Resource::ImageType);

            if (!res) {

                // TODO error event
            }
            else {

                res->setId(Crypto::mkId());

                setResource(res);

                return res->getId();
            }
        }
    }
    */

    return 0;
}

/**
 * @brief Backend::prepareStore
 * @return
 */

bool Backend::prepareStore()
{
    m_storeDir = "/sdcard/Zway";

    QDir dir(m_storeDir);

    if (!dir.exists()) {

        dir.mkpath(m_storeDir);

        dir.cd(m_storeDir);
    }


    QStringList filter;

    filter.append(QStringLiteral("*.store"));

    QFileInfoList list = dir.entryInfoList(filter);

    if (list.size() == 1 && list[0].isFile()) {

        m_storeFile = list[0].absoluteFilePath();
    }

    return true;
}

/**
 * @brief Backend::readPhoneContacts
 * @param res
 * @return
 */

bool Backend::readPhoneContacts(QJsonObject &res)
{
    /*
    QAndroidJniObject obj = QAndroidJniObject::callStaticObjectMethod(
            "de.atomicode.zway.ZwayActivity",
            "getContactsJson",
            "()Ljava/lang/String;");

    QString phoneContactsJson = obj.toString();

    if (!phoneContactsJson.isEmpty()) {

        QJsonDocument doc = QJsonDocument::fromJson(phoneContactsJson.toUtf8());

        if (doc.isObject()) {

            res = doc.object().toVariantMap();
        }

        return true;
    }
    */

    return false;
}

/**
 * @brief Backend::readPhoneContactsHex
 * @param res
 * @return
 */

bool Backend::readPhoneContactsHex(QMap<QString, QString> &res)
{
    /*
    QVariantMap contacts;

    if (readPhoneContacts(contacts)) {

        for (auto it = contacts.begin(); it != contacts.end(); ++it) {

            QVariantList numbers = it.value().toList();

            for (auto number : numbers) {

                QString fns = formatPhoneNumber(number.toString());

                if (!fns.isEmpty()) {

                    std::string md5hex = Crypto::Digest::digestHexStr((uint8_t*)fns.constData(), fns.length());

                    res[md5hex.c_str()] = it.key();
                }
            }
        }

        return true;
    }
    */

    return false;
}

/**
 * @brief Backend::onNativeCallback
 * @param type
 * @param data
 */

void Backend::onNativeCallback(qint32 id, const QJsonObject &data)
{
    if (id == 1000) {

        if (data["permissionsGranted"].toBool()) {


            m_fcmToken = data["fcmToken"].toString();


            prepareStore();


            emit ready(false, m_storeFile, QString());


        }
        else {

            // ...
        }
    }
    else
    if (id == 2000) {

        // fcm token changed

        m_fcmToken = data["fcmToken"].toString();

        // ...
    }
}

// ============================================================ //
