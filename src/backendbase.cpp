
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

#include "backendbase.h"

#include <QScreen>
#include <QStyleHints>
#include <QQmlContext>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QRegularExpression>

#include <Zway/crypto/crypto.h>
#include <Zway/message/resource.h>
#include <Zway/request/configrequest.h>
#include <Zway/request/dispatchrequest.h>
#include <Zway/request/requestevent.h>
#include <Zway/store.h>

// ============================================================ //

BackendBase *BackendBase::m_instance = nullptr;

/**
 * @brief BackendBase::instance
 * @return
 */

BackendBase *BackendBase::instance()
{
    return m_instance;
}

/**
 * @brief BackendBase::BackendBase
 * @param app
 * @param engine
 */

BackendBase::BackendBase(QGuiApplication *app, QQmlEngine *engine)
    : QObject(engine),
      m_engine(engine),
      m_dp(1),
      m_sp(1),
      m_active(true),
      m_contactModel(this),
      m_fileSystemModel(this),
      m_localStoreModel(this)
{
    m_instance = this;

    QString dpiPrefix = "mdpi";

#if defined Q_OS_ANDROID || defined Q_OS_IOS

    qreal dpi = app->primaryScreen()->physicalDotsPerInch();

    if (dpi > 560) {
        dpiPrefix = "xxxhdpi";
        m_dp = 4;
        m_sp = 4;
    }
    else
    if (dpi > 400 && dpi <= 560) {
        dpiPrefix = "xxhdpi";
        m_dp = 3;
        m_sp = 3;
    }
    else
    if (dpi > 280 && dpi <= 400) {
        dpiPrefix = "xhdpi";
        m_dp = 2;
        m_sp = 2;
    }
    else
    if (dpi > 200 && dpi <= 280) {
        dpiPrefix = "hdpi";
        m_dp = 1.5;
        m_sp = 1.5;
    }

    // adjust threshold for drag operations

    app->styleHints()->setStartDragDistance(10 * m_dp);

#endif

    QQmlContext* context = m_engine->rootContext();

    context->setContextProperty(QStringLiteral("dpiPrefix"), dpiPrefix);
    context->setContextProperty(QStringLiteral("dp"), m_dp);
    context->setContextProperty(QStringLiteral("sp"), m_sp);
    context->setContextProperty(QStringLiteral("backend"), this);
    context->setContextProperty(QStringLiteral("contactModel"), &m_contactModel);
    context->setContextProperty(QStringLiteral("fileSystemModel"), &m_fileSystemModel);
    context->setContextProperty(QStringLiteral("localStoreModel"), &m_localStoreModel);

    QJsonDocument doc;

    QFile f(":/res/themes/default.json");

    if (f.open(QFile::ReadOnly | QFile::Text)) {

        doc = QJsonDocument::fromJson(f.readAll());
    }

    if (doc.isObject()) {

        context->setContextProperty("theme", doc.object());
    }


    context->setContextProperty(QStringLiteral("statusBarHeight"), 0.f);


    QObject::connect(app, &QGuiApplication::applicationStateChanged, this, &BackendBase::onApplicationStateChanged);

    QObject::connect(this, &BackendBase::invokeCallback, this, &BackendBase::onInvokeCallback);

}

/**
 * @brief BackendBase::~BackendBase
 */

BackendBase::~BackendBase()
{

}

/**
 * @brief BackendBase::start
 * @param host
 * @param port
 * @return
 */

bool BackendBase::start(const QString &host, uint16_t port, EventHandlerCallback handler)
{
    if (!Client::startup()) {

        return false;
    }

    m_eventHandler = EventHandler$(new EventHandler());

    m_eventHandler->addHandler(shared_from_this(), handler);

    m_eventHandler->start();

    if (!Client::start(host.toStdString(), port)) {

        return false;
    }

    if (!ImageService::startup(this)) {

        return false;
    }

    QQmlContext* context = m_engine->rootContext();

    context->setContextProperty(QStringLiteral("ImageService"), ImageService::instance());

    context->engine()->addImageProvider(QStringLiteral("thumbs"), ImageService::instance()->createImageProvider());

    return true;
}

/**
 * @brief BackendBase::close
 * @return
 */

bool BackendBase::close()
{
    Client::close();

    m_eventHandler->cancelAndJoin();

    m_eventHandler->clearHandlers();

    m_eventHandler->clear();

    m_eventHandler.reset();

    Client::cleanup();

    ImageService::cleanup();

    return true;
}

/**
 * @brief BackendBase::onEvent
 * @param client
 * @param event
 */

void BackendBase::onEvent(Client$ client, Event$ event)
{
    if (event->error().size()) {

        emit handleLog(3, ubjToJsonObj(event->error()));
    }

    switch (event->type()) {

    case Event::Status:

        emit clientStatusChanged(client->status());

        break;

    case Event::RequestTimeout: {

        break;
    }

    case Event::ConnectionSuccess:

        emit connectionSuccess();

        break;

    case Event::ConnectionFailure:

        emit connectionFailure(ubjToJsonObj(event->data()));

        break;

    case Event::ConnectionInterrupted:

        emit connectionInterrupted();

        break;

    case Event::Disconnected:

        emit disconnected();

        break;

    case Event::LoginSuccess: {

        emit loginSuccess();

        break;
    }

    case Event::ContactRequest: {

        emit contactRequest(ubjToJsonObj(event->data()));

        break;
    }

    case Event::ContactRequestAccepted: {

        emit contactRequestAccepted(ubjToJsonObj(event->data()));

        break;
    }

    case Event::ContactRequestRejected: {

        emit contactRequestRejected(ubjToJsonObj(event->data()));

        break;
    }

    case Event::ContactStatus:

        emit contactStatusChanged();

        break;

    case Event::MessageIncoming: {

        UBJ::Object message = event->data()["message"];

        emit messageIncoming(ubjToJsonObj(message));

        break;
    }

    case Event::MessageOutgoing: {

        UBJ::Object message = event->data()["message"];

        emit messageOutgoing(ubjToJsonObj(message));

        break;
    }

    case Event::MessageReceived: {

        UBJ::Object message = event->data()["message"];

        emit messageReceived(ubjToJsonObj(message));

        break;
    }

    case Event::MessageSent: {

        UBJ::Object message = event->data()["message"];

        emit messageSent(ubjToJsonObj(message));

        break;
    }

    case Event::MessageDelivered: {

        UBJ::Object message = event->data()["message"];

        emit messageDelivered(ubjToJsonObj(message));

        break;
    }

    case Event::ResourceReceived: {

        UBJ::Object message = event->data()["message"];

        UBJ::Object resource = event->data()["resource"];

        processResourceRecv(message, resource);

        emit resourceReceived(ubjToJsonObj(message), ubjToJsonObj(resource));

        break;
    }

    case Event::ResourceSent: {

        UBJ::Object message = event->data()["message"];

        UBJ::Object resource = event->data()["resource"];

        /*
        if (resource->hasField("replaceOnSent")) {

            uint32_t blobId = 0;

            uint32_t recordId = (*resource)["recordId"].toInt();

            UBJ::Object replaceOnSent = (*resource)["replaceOnSent"];

            if (resource->hasField("noStore")) {

                // ...
            }
            else {

                blobId = (*resource)["blobId"].toInt();
            }

            if (blobId) {

                QString resourceUrl = replaceOnSent["resourceUrl"].toStr().c_str();

                QString path = replaceOnSent["path"].toStr().c_str();

                Message::Lock lock(*message);

                QString text = message->text().c_str();

                QString resourceUrl2 = resourceUrl;

                resourceUrl2
                        .replace(path, QString("%0").arg(blobId))
                        .replace(QRegularExpression("blobId=\\d+"), QString("blobId=%0&resourceId=%1").arg(blobId).arg(recordId))
                        .replace(QRegularExpression("source=\\d+"), "source=2");

                text.replace(resourceUrl, resourceUrl2);

                message->setText(text.toStdString());

                m_store->update("messages", UBJ_OBJ("text" << message->text()), UBJ_OBJ("id" << message->id()));
            }
        }
        */

        emit resourceSent(ubjToJsonObj(message), ubjToJsonObj(resource));

        break;
    }

    case Event::ResourceDelivered: {

        UBJ::Object message = event->data()["message"];

        UBJ::Object resource = event->data()["resource"];

        emit resourceDelivered(ubjToJsonObj(message), ubjToJsonObj(resource));

        break;
    }

    default:

        break;
    }
}

/**
 * @brief BackendBase::createAccount
 * @param args
 * @param callback
 * @return
 */

bool BackendBase::createAccount(const QJsonObject &args, const QJSValue &callback)
{
    return request({
                {"requestType", Request::CreateAccount},
                {"name"       , args["name"].toString().toStdString()},
                {"password"   , args["password"].toString().toStdString()},
                {"findByName" , args["findByName"].toBool()},
                {"storeDir"   , m_storeDir.toStdString()}
            },
            [this,callback] (RequestEvent$ event, Request$) {

                emit invokeCallback(
                    callback, {
                        ubjToJson(event->error()),
                        ubjToJson(event->data())
                    });
            });

    return true;
}

/**
 * @brief BackendBase::deleteAccount
 * @return
 */

bool BackendBase::deleteAccount()
{
    return false;
}

/**
 * @brief BackendBase::login
 * @return
 */

void BackendBase::login()
{
    request(UBJ_OBJ("requestType" << Request::Login));
}

/**
 * @brief BackendBase::logout
 */

void BackendBase::logout()
{
    if (status() >= Authenticated) {

        request(UBJ_OBJ("requestType" << Request::Logout), [] (RequestEvent$, Request$) {

            QGuiApplication::quit();
        });
    }
    else {

        QGuiApplication::quit();
    }
}

/**
 * @brief BackendBase::setConfig
 * @param config
 * @param callback
 * @return
 */

bool BackendBase::setConfig(const QJsonObject &config, const QJSValue &callback)
{
    auto obj = jsonToUbj(config);

    if (!store()->setConfig(obj)) {

        return false;
    }

    auto req = ConfigRequest::create(
                shared_from_this(), obj,
                [this, callback] (RequestEvent$ event, Request$) {

                    emit invokeCallback(
                            callback,
                            {
                                ubjToJson(event->error()),
                                ubjToJson(event->data())
                            });
                });

    if (req) {

        return postRequest(req);
    }

    return false;
}

/**
 * @brief BackendBase::addContact
 * @param addCode
 * @param name
 * @param phone
 * @param callback
 * @return
 */

bool BackendBase::addContact(
        const QString &addCode,
        const QString &name,
        const QString &phone,
        const QJSValue &callback)
{
    return request({
                {"requestType", Request::AddContact},
                {"addCode"    , addCode.toStdString()},
                {"name"       , name.toStdString()},
                {"phone"      , phone.toStdString()}
            },
            [this,callback] (RequestEvent$ event, Request$) {

                emit invokeCallback(
                    callback, {
                        ubjToJson(event->error()),
                        ubjToJson(event->data())
                    });
            });
}

/**
 * @brief BackendBase::createAddCode
 * @param callback
 * @return
 */

bool BackendBase::createAddCode(const QJSValue &callback)
{
    return request({
                {"requestType", Request::CreateAddCode}
            },
            [this,callback] (RequestEvent$ event, Request$) {

                emit invokeCallback(
                    callback, {
                        ubjToJson(event->error()),
                        ubjToJson(event->data())
                    });
            });
}

/**
 * @brief BackendBase::acceptContact
 * @param requestId
 * @param callback
 * @return
 */

bool BackendBase::acceptContact(quint32 requestId, const QJSValue &callback)
{
    return request({
                {"requestType"     , Request::AcceptContact},
                {"contactRequestId", requestId}
            },
            [this,callback] (RequestEvent$ event, Request$) {

                emit invokeCallback(
                    callback, {
                        ubjToJson(event->error()),
                        ubjToJson(event->data())
                    });
            });
}

/**
 * @brief BackendBase::rejectContact
 * @param requestId
 * @param callback
 * @return
 */

bool BackendBase::rejectContact(quint32 requestId, const QJSValue &callback)
{
    return request({
                {"requestType"     , Request::RejectContact},
                {"contactRequestId", requestId}
            },
            [this,callback] (RequestEvent$ event, Request$) {

                emit invokeCallback(
                    callback, {
                        ubjToJson(event->error()),
                        ubjToJson(event->data())
                    });
            });
}

/**
 * @brief BackendBase::cancelRequest
 * @param requestId
 * @param callback
 * @return
 */

bool BackendBase::cancelRequest(quint32 requestId, const QJSValue &callback)
{
    return processDispatchRequest({
                {"dispatchId"    , requestId},
                {"dispatchAction", "cancel"},
            },
            [this,callback,requestId] (RequestEvent$ event, Request$) {

                emit invokeCallback(
                    callback, {
                        ubjToJson(event->error()),
                        ubjToJson(event->data())
                    });
            });
}

/**
 * @brief BackendBase::postMessage
 * @param message
 * @return
 */

bool BackendBase::postMessage(const QJsonObject &message)
{
    quint32 src = store()->accountId();

    quint32 dst = message["dst"].toInt();

    QString srcText = message["text"].toString();

    QString dstText = srcText;

    // create message

    Message$ msg = Message::create();

    msg->setSrc(src);

    msg->setDst(dst);

    // resources

    for (auto item : message["resources"].toArray()) {

        QJsonObject resMap = item.toObject();

        qint32 origin = resMap["origin"].toInt();

        QString resourceUrl = resMap["thumbUrl"].toString().replace("&", "&amp;");

        if (origin == ImageService::SOURCE_FILE_SYSTEM) {

            QString path = resMap["path"].toString();
            QString name = resMap["name"].toString();

            // skip resources which are not included

            if (dstText.indexOf("href=\"" + resourceUrl) == -1) {

                continue;
            }

            Resource$ res = FileSystemResource::create(path.toStdString(), name.toStdString());

            if (!res) {

                // TODO error event

                return false;
            }

            res->setId(Crypto::mkId());

            // try to find node with same name in outgoing dir

            /*
            uint32_t outDir = ioDir(dst, "Outgoing");

            uint32_t blobId = 0;

            UBJ::Object node;

            if (m_store->query(
                        "vfs",
                        UBJ_OBJ(
                            "type"   << VfsFileType <<
                            "name"   << res->name() <<
                            "parent" << outDir),
                        node)) {

                // has this node the same hash

                if (node["hash"].toStr() == res->hash()) {

                    blobId = node["data"].toInt();

                    (*res)["noStore"] = true;
                }
                else {

                    // rename node

                    // ...
                }
            }

            // set replace data

            (*res)["replaceOnSent"] = UBJ_OBJ(
                        "resourceUrl" << resourceUrl.toStdString() <<
                        "path"        << path.toStdString() <<
                        "blobId"      << blobId);
            */

            // replace path with new resource id in recipient text

            QString resourceUrl2 = resourceUrl;

            resourceUrl2
                    .replace(path, QString("%0").arg(res->id()))
                    .replace(QRegularExpression("blobId=\\d+"), QString("resourceId=%0").arg(res->id()))
                    .replace(QRegularExpression("source=\\d+"), "source=2");

            dstText.replace(resourceUrl, resourceUrl2);

            msg->addResource(res);
        }
        else
        if (origin == ImageService::SOURCE_LOCAL_STORE) {

            quint32 resId = resMap["id"].toInt();

            if (dstText.indexOf("href=\"" + resourceUrl) == -1) {

                continue;
            }

            Resource$ res = LocalStoreResource::create(store(), 0, resId);

            if (res) {

                // create new resource id

                res->setId(Crypto::mkId());

                // replace path with new resource id in recipient text

                QString src = QString("//thumbs/%0").arg(resId);

                QString dst = QString("//thumbs/%0").arg(res->id());

                dstText
                        .replace(src, dst)
                        .replace(QRegularExpression("blobId=\\d+"), QString("resourceId=%0").arg(res->id()));

                msg->addResource(res);
            }
            else {

                // TODO error event
            }
        }
    }

    // set message text

    msg->setField("text", srcText.toStdString());

    msg->setField("meta", UBJ_OBJ("text" << dstText.toStdString()));

    // post message

    if (!Client::postMessage(msg)) {

        return false;
    }

    return true;
}

/**
 * @brief BackendBase::accountId
 * @return
 */

quint32 BackendBase::accountId()
{
    return store()->accountId();
}

/**
 * @brief BackendBase::accountLabel
 * @return
 */

QString BackendBase::accountName()
{
    return QString::fromStdString(store()->accountName());
}

/**
 * @brief BackendBase::connected
 * @return
 */

bool BackendBase::connected()
{
    return status() >= Client::Secure;
}

/**
 * @brief BackendBase::loggedIn
 * @return
 */

bool BackendBase::loggedIn()
{
    return status() >= Client::Authenticated;
}

/**
 * @brief BackendBase::getConfig
 * @param request
 * @return
 */

QJsonValue BackendBase::getConfig(bool request, const QJSValue &callback)
{
    Q_UNUSED(callback)

    UBJ::Object config;

    if (!request) {

        if (store()->getConfig(config)) {

            return ubjToJson(config);
        }
    }

    return QJsonValue();
}

/**
 * @brief BackendBase::getContact
 * @param contactId
 * @return
 */

QJsonValue BackendBase::getContact(quint32 contactId)
{
    UBJ::Object contact;

    if (store()->query("contacts", UBJ_OBJ("id" << contactId), &contact, {}, {"id", "name", "phone", "color"})) {

        return ubjToJson(contact);
    }

    return QJsonValue();
}

/**
 * @brief BackendBase::latestHistoryId
 * @param dst
 * @return
 */

quint32 BackendBase::latestHistoryId(quint32 dst)
{
    return store()->latestHistory(dst);
}

/**
 * @brief BackendBase::latestHistoryModel
 * @param dst
 * @return
 */

QVariant BackendBase::latestHistoryModel(quint32 dst)
{
    uint32_t historyId = store()->latestHistory(dst);

    if (historyId) {

        if (m_historyModels.contains(historyId)) {

            return QVariant::fromValue(m_historyModels[historyId].get());
        }
        else {

            HistoryModel* model = new HistoryModel(this, historyId);

            m_historyModels[historyId] = std::shared_ptr<HistoryModel>(model);

            return QVariant::fromValue(model);
        }
    }

    return QVariant();
}

/**
 * @brief Backend::deleteRequest
 * @param id
 * @param callback
 */

void BackendBase::deleteRequest(quint32 id, const QJSValue &callback)
{
    LambdaRunnable::start([this, id, callback] {

        if (!store()->remove("contact_requests", UBJ_OBJ("id" << id))) {

        }

        emit invokeCallback(callback);
    });
}

/**
 * @brief BackendBase::deleteHistory
 * @param id
 * @param callback
 * @return
 */

bool BackendBase::deleteHistory(quint32 id, const QJSValue &callback)
{
    LambdaRunnable::start([this, id, callback] {

        if (store()->deleteHistory(id)) {

            m_historyModels.remove(id);
        }

        emit invokeCallback(callback);
    });

    return true;
}

/**
 * @brief BackendBase::deleteContact
 * @param id
 * @param callback
 */

void BackendBase::deleteContact(quint32 id, const QJSValue &callback)
{
    LambdaRunnable::start([this, id, callback] {

        if (!store()->remove("contacts", UBJ_OBJ("id" << id))) {

        }

        emit invokeCallback(callback);
    });
}

/**
 * @brief BackendBase::updateInbox
 * @param contactId
 * @param messageId
 * @return
 */

quint32 BackendBase::updateInbox(quint32 contactId, quint32 messageId)
{
    return m_store->updateInbox(contactId, {messageId});
}

/**
 * @brief BackendBase::resetInbox
 * @param contactId
 */

void BackendBase::resetInbox(quint32 contactId)
{
    m_store->resetInbox(contactId);
}

/**
 * @brief BackendBase::findContact
 * @param query
 * @param callback
 * @return
 */

bool BackendBase::findContact(const UBJ::Value &query, RequestCallback callback)
{
    return request({
                {"requestType", Request::FindContact},
                {"query"      , query}
            },
            callback);
}

/**
 * @brief BackendBase::processDispatchRequest
 * @param args
 * @param callback
 * @return
 */

bool BackendBase::processDispatchRequest(const UBJ::Object &args, RequestCallback callback)
{
    return postRequest(DispatchRequest::create(
                    shared_from_this(),
                    args,
                    [=] (RequestEvent$ event, Request$ request) {

        if (args["dispatchAction"].toStr() == "cancel") {

            if (!store()->remove("contact_requests", UBJ_OBJ("id" << args["dispatchId"].toInt()))) {

            }
        }

        if (callback) {

            callback(event, request);
        }
    }));
}

/**
 * @brief BackendBase::processResourceRecv
 * @param message
 * @param resource
 * @return
 */

bool BackendBase::processResourceRecv(UBJ::Object &message, UBJ::Object &resource)
{
    /*
    UBJ::Object data = messageEvent->data();

    if (data.hasField("replaced")) {

        UBJ::Object messageUserData = (*message)["userData"];

        if (messageUserData.hasField("displayText")) {

            QString displayText = messageUserData["displayText"].toStr().c_str();

            QString src = QString("//thumbs/%0").arg((quint32)data["replaced"]["src"].toInt());

            QString dst = QString("//thumbs/%0").arg((quint32)data["replaced"]["dst"].toInt());

            displayText.replace(src, dst);

            messageUserData["displayText"] = displayText.toStdString();

            {
                Message::Lock lock(*message);

                (*message)["userData"] = messageUserData;

                //m_store->updateMessage(message);
            }
        }
    }
    */

    uint32_t resId = resource["id"].toInt();

    uint32_t blobId = resource["data"].toInt();

    if (blobId) {

        // update message text

        QString text = message["text"].toStr().c_str();

        message["text"] = text
                .replace(QString("resourceId=%0").arg(resId), QString("blobId=%0&resourceId=%1").arg(blobId).arg(resId))
                .toStdString();

        if (!store()->update("messages", UBJ_OBJ("text" << message["text"]), UBJ_OBJ("id" << message["id"]))) {

            return false;
        }

        // create vfs node

        uint32_t src = message["src"].toInt();

        uint32_t incDir = store()->ioDir(src, "Incoming");

        if (!store()->insert(
                    "vfs",
                    UBJ_OBJ(
                        "id"     << resource["id"] <<
                        "type"   << Store::File <<
                        "status" << 0 <<
                        "parent" << incDir <<
                        "time"   << (uint64_t)time(nullptr) <<
                        "name"   << resource["name"] <<
                        "size"   << resource["size"] <<
                        "hash"   << resource["hash"] <<
                        "data"   << blobId))) {

            return false;
        }
    }

    return true;
}

/**
 * @brief BackendBase::jsonToUbj
 * @param val
 * @return
 */

UBJ::Value BackendBase::jsonToUbj(const QJsonValue &val)
{
    switch (val.type()) {
    case QJsonValue::Object:
        return jsonObjToUbj(val.toObject());
    case QJsonValue::Array:
        return jsonArrToUbj(val.toArray());
    case QJsonValue::String:
        return val.toString().toStdString();
    case QJsonValue::Double: {

        int v = val.toInt();

        if (v) {

            return v;
        }
        else {

            return val.toDouble();
        }
    }
    case QJsonValue::Bool:
        return val.toBool();
    default:
        return UBJ::Value();;
    }
}

/**
 * @brief Backend::variantMapToUbj
 * @param map
 * @return
 */

UBJ::Object BackendBase::jsonObjToUbj(const QJsonObject &obj)
{
    UBJ::Object ubj;

    for (QJsonObject::const_iterator it = obj.begin(); it != obj.end(); ++it) {

        ubj[it.key().toStdString()] = jsonToUbj(*it);
    }

    return ubj;
}

/**
 * @brief Backend::variantListToUbj
 * @param list
 * @return
 */

UBJ::Array BackendBase::jsonArrToUbj(const QJsonArray &arr)
{
    UBJ::Array ubj;

    for (QJsonArray::const_iterator it = arr.begin(); it != arr.end(); ++it) {

        ubj << jsonToUbj(*it);
    }

    return ubj;
}

/**
 * @brief BackendBase::ubjToJsonVal
 * @param ubj
 * @return
 */

QJsonValue BackendBase::ubjToJson(const UBJ::Value &val, bool nullIfEmpty)
{
    switch (val.type()) {
    case UBJ_OBJECT:
        return nullIfEmpty ? (val.numItems() ? ubjToJsonObj(val) : QJsonValue()) : ubjToJsonObj(val);
    case UBJ_ARRAY:
        return nullIfEmpty ? (val.numItems() ? ubjToJsonArr(val) : QJsonValue()) : ubjToJsonArr(val);
    case UBJ_STRING:
        return QString::fromStdString(val.toStr());
    case UBJ_INT32:
    case UBJ_INT64:
        return val.toInt();
    case UBJ_FLOAT32:
    case UBJ_FLOAT64:
        return val.toDouble();
    case UBJ_BOOL_TRUE:
    case UBJ_BOOL_FALSE:
        return val.toBool();
    default:
        return QJsonValue();
    }
}

/**
 * @brief BackendBase::ubjToJsonObj
 * @param ubj
 * @return
 */

QJsonObject BackendBase::ubjToJsonObj(const UBJ::Value &ubj)
{
    QJsonObject obj;

    if (ubj.isObject()) {

        for (auto &it : ubj.obj()) {

            obj[QString::fromStdString(it.first)] = ubjToJson(it.second);
        }
    }

    return obj;
}

/**
 * @brief BackendBase::ubjToJsonArr
 * @param ubj
 * @return
 */

QJsonArray BackendBase::ubjToJsonArr(const UBJ::Value &ubj)
{
    QJsonArray arr;

    if (ubj.isArray()) {

        for (auto &it : ubj.arr()) {

            arr.append(ubjToJson(it));
        }
    }

    return arr;
}

/**
 * @brief BackendBase::engine
 * @return
 */

QQmlEngine *BackendBase::engine()
{
    return m_engine;
}

/**
 * @brief BackendBase::onApplicationStateChanged
 * @param state
 */

void BackendBase::onApplicationStateChanged(Qt::ApplicationState state)
{
    if (state == Qt::ApplicationSuspended) {

        m_active = false;
    }
    else
    if (state == Qt::ApplicationActive) {

        m_active = true;
    }
}

/**
 * @brief BackendBase::onInvokeCallback
 * @param callback
 * @param args
 */

void BackendBase::onInvokeCallback(const QJSValue &callback, const QVariantList &args)
{
    if (callback.isCallable()) {

        QJSValueList a;

        for (auto &v : args) {

            a.append(engine()->toScriptValue(v));
        }

        QJSValue v(callback);

        v.call(a);
    }
}

// ============================================================ //

/**
 * @brief LambdaRunnable::start
 * @param f
 * @return
 */

LambdaRunnable *LambdaRunnable::start(std::function<void ()> f)
{
    LambdaRunnable* r = new LambdaRunnable(f);

    QThreadPool::globalInstance()->start(r);

    return r;
}

/**
 * @brief LambdaRunnable::LambdaRunnable
 * @param f
 */

LambdaRunnable::LambdaRunnable(std::function<void ()> f)
    : QRunnable(),
      m_f(f)
{

}

/**
 * @brief LambdaRunnable::run
 */

void LambdaRunnable::run()
{
    m_f();
}

// ============================================================ //
