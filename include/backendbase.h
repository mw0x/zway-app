
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

#ifndef ZWAY_BACKEND_BASE_H_
#define ZWAY_BACKEND_BASE_H_

#include <QGuiApplication>
#include <QQmlEngine>
#include <QJSValue>
#include <QRunnable>

#include "imageservice.h"
#include "contactmodel.h"
#include "historymodel.h"
#include "filesystemmodel.h"
#include "localstoremodel.h"

#include <Zway/client.h>

// ============================================================ //

/**
 * @brief The BackendBase class
 */

class BackendBase : public QObject, public Client
{
    Q_OBJECT

public:

    static BackendBase* instance();


    BackendBase(QGuiApplication *app, QQmlEngine *engine);

    virtual ~BackendBase();


    bool start(const QString &host, uint16_t port, EVENT_HANDLER_CALLBACK handler);

    bool close();


    void onEvent(CLIENT client, EVENT event);


    qreal dp() { return m_dp; }

    qreal sp() { return m_sp; }


    Q_INVOKABLE bool createAccount(const QJsonObject &args, const QJSValue &callback = QJSValue());

    Q_INVOKABLE bool deleteAccount();

    Q_INVOKABLE void login();

    Q_INVOKABLE void logout();

    Q_INVOKABLE bool setConfig(const QJsonObject &config, const QJSValue &callback = QJSValue());

    Q_INVOKABLE bool addContact(const QString &addCode, const QString &name, const QString &phone, const QJSValue &callback = QJSValue());

    Q_INVOKABLE bool createAddCode(const QJSValue &callback = QJSValue());

    Q_INVOKABLE bool acceptContact(quint32 requestId, const QJSValue &callback = QJSValue());

    Q_INVOKABLE bool rejectContact(quint32 requestId, const QJSValue &callback = QJSValue());

    Q_INVOKABLE bool cancelRequest(quint32 requestId, const QJSValue &callback = QJSValue());

    Q_INVOKABLE bool postMessage(const QJsonObject &message);


    Q_INVOKABLE quint32 accountId();

    Q_INVOKABLE QString accountName();


    Q_INVOKABLE bool connected();

    Q_INVOKABLE bool loggedIn();


    Q_INVOKABLE QJsonValue getConfig(bool request = false, const QJSValue &callback = QJSValue());


    Q_INVOKABLE QJsonValue getContact(quint32 contactId);


    Q_INVOKABLE quint32 latestHistoryId(quint32 dst);

    Q_INVOKABLE QVariant latestHistoryModel(quint32 dst);


    Q_INVOKABLE void deleteRequest(quint32 id, const QJSValue &callback = QJSValue());

    Q_INVOKABLE bool deleteHistory(quint32 id, const QJSValue &callback = QJSValue());

    Q_INVOKABLE void deleteContact(quint32 id, const QJSValue &callback = QJSValue());


    Q_INVOKABLE quint32 updateInbox(quint32 contactId, quint32 messageId);

    Q_INVOKABLE void resetInbox(quint32 contactId);


    bool findContact(const UBJ::Value &query, REQUEST_CALLBACK callback = nullptr);


    bool processDispatchRequest(const UBJ::Object &args, REQUEST_CALLBACK callback=nullptr);

    bool processResourceRecv(UBJ::Object &message, UBJ::Object &resource);


    static UBJ::Value jsonToUbj(const QJsonValue &val);

    static UBJ::Object jsonObjToUbj(const QJsonObject &obj);

    static UBJ::Array jsonArrToUbj(const QJsonArray &arr);

    static QJsonValue ubjToJson(const UBJ::Value &val, bool nullIfEmpty=true);

    static QJsonObject ubjToJsonObj(const UBJ::Value &ubj);

    static QJsonArray ubjToJsonArr(const UBJ::Value &ubj);


    QQmlEngine *engine();


private slots:

    void onApplicationStateChanged(Qt::ApplicationState state);

    void onInvokeCallback(const QJSValue &callback, const QVariantList &args);


signals:

    void handleLog(quint32 type, const QJsonObject &log);

    void invokeCallback(const QJSValue &callback, const QVariantList &args = QVariantList());

    void ready(bool err, const QString &filename, const QString &password);

    void storeUnlocked();

    void clientStatusChanged(qint32 status);

    void connectionSuccess();

    void connectionFailure(const QJsonObject &args);

    void connectionInterrupted();

    void disconnected();

    void reconnected();

    void loginSuccess();

    void contactRequest(const QJsonObject &args);

    void contactRequestAccepted(const QJsonObject &args);

    void contactRequestRejected(const QJsonObject &args);

    void contactStatusChanged();

    void messageIncoming(const QJsonObject &message);

    void messageOutgoing(const QJsonObject &message);

    void messageSent(const QJsonObject &message);

    void messageReceived(const QJsonObject &message);

    void messageDelivered(const QJsonObject &message);

    void messageReceipted(const QJsonObject &message);

    void resourceIncoming(const QJsonObject &message, const QJsonObject &resource);

    void resourceOutgoing(const QJsonObject &message, const QJsonObject &resource);

    void resourceSent(const QJsonObject &message, const QJsonObject &resource);

    void resourceReceived(const QJsonObject &message, const QJsonObject &resource);

    void resourceDelivered(const QJsonObject &message, const QJsonObject &resource);

    void resourceReceiped(const QJsonObject &message, const QJsonObject &resource);

    void nativeCallback(qint32 type, const QJsonObject &data);


protected:

    static BackendBase *m_instance;

    QQmlEngine *m_engine;

    qreal m_dp;

    qreal m_sp;

    bool m_active;

    ContactModel m_contactModel;

    FileSystemModel m_fileSystemModel;

    LocalStoreModel m_localStoreModel;

    QMap<quint32, std::shared_ptr<HistoryModel>> m_historyModels;

    QString m_storeDir;

    QString m_storeFile;
};

// ============================================================ //

class LambdaRunnable : public QRunnable
{
public:
    static LambdaRunnable *start(std::function<void ()> f);

    LambdaRunnable(std::function<void ()> f);

    void run();

private:

    std::function<void ()> m_f;
};

// ============================================================ //

#endif
