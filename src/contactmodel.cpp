
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

#include "contactmodel.h"
#include "backendbase.h"

#include <QJsonObject>

#include <Zway/request.h>
#include <Zway/request/requestevent.h>
#include <Zway/ubj/store/cursor.h>
#include <Zway/store.h>

// ============================================================ //

/**
 * @brief ContactModel::ContactModel
 * @param backend
 */

ContactModel::ContactModel(BackendBase *backend) :
    QAbstractListModel(backend),
    m_backend(backend)
{
    QObject::connect(this, &ContactModel::updateView, this, &ContactModel::onUpdateView);
}

/**
 * @brief ContactModel::rowCount
 * @param parent
 * @return
 */

int ContactModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)

    return m_items.size();
}

/**
 * @brief ContactModel::data
 * @param index
 * @param role
 * @return
 */

QVariant ContactModel::data(const QModelIndex &index, int role) const
{
    if (index.row() < 0 || index.row() > m_items.size()) {

        return QVariant();
    }

    const QJsonObject item = m_items[index.row()].toObject();

    switch (role) {
        case IdRole:
            return item["id"];
        case TypeRole:
            return item["type"];
        case GroupRole:
            return item["group"];
        case ColorRole:
            return item["color"];
        case NameRole:
            return item["name"];
        case PhoneRole:
            return item["phone"];
        case StatusRole:
            return item["status"];
        case InboxRole:
            return item["inbox"];
        case AddCodeRole:
            return item["addCode"];
    }

    return QVariant();
}

/**
 * @brief ContactModel::get
 * @param index
 * @return
 */

QJsonValue ContactModel::get(int index)
{
    if (index >= 0 && index < m_items.size()) {

        return m_items[index].toObject();
    }

    return QJsonValue();
}

/**
 * @brief ContactModel::updateItems
 * @param filter
 * @param searchOnline
 * @param callback
 */

void ContactModel::updateItems(const QString &filter, const QString &searchOnline, const QJSValue &callback)
{
    if (!searchOnline.isEmpty()) {

        m_backend->findContact(

                UBJ_OBJ("subject" << searchOnline.toStdString()),

                [this, callback] (RequestEvent$ event, Request$) {

                    QJsonArray items;

                    for (auto &it : event->data()["result"].toArray()) {

                        QJsonObject item = m_backend->ubjToJsonObj(it);

                        item["color"] = QString::fromStdString(m_backend->store()->randomColor());

                        items.append(item);
                    }

                    emit updateView(items);

                    emit m_backend->invokeCallback(callback);
                });
    }
    else {

        LambdaRunnable::start([=] {

            QJsonArray items;

            m_backend->store()->query(
                        "contact_requests", {},
                        [&] (bool error, Zway::UBJ::Store::Cursor$ cursor) {

                if (!error) {

                    cursor->forEach([&] (UBJ::Object &request) {

                        QJsonObject map;

                        qint32 type = request["src"].toUInt() == m_backend->store()->accountId() ? 1 : 2;

                        qint32 result = request["result"].toInt();

                        if (result == Request::AcceptContact) {

                            type = 3;
                        }
                        else
                        if (result == Request::RejectContact) {

                            type = 4;
                        }

                        map["id"]      = request["id"].toInt();
                        map["type"]    = type;
                        map["group"]   = "request";
                        map["color"]   = request["color"].toStr().c_str();
                        map["status"]  = 0;
                        map["name"]    = request["name"].toStr().c_str();
                        map["phone"]   = request["phone"].toStr().c_str();
                        map["addCode"] = request["addCode"].toStr().c_str();

                        items.append(map);
                    });
                }
            });

            m_backend->store()->query(
                        "contacts", {}, UBJ_OBJ("name" << 1), {}, 0, 0,
                        [&] (bool error, UBJ::Store::Cursor$ cursor) {

                if (!error) {

                    cursor->forEach([&] (UBJ::Object &contact) {

                        QString name = contact["name"].toStr().c_str();

                        if (filter.isEmpty() || name.indexOf(filter, 0, Qt::CaseInsensitive) != -1) {

                            QJsonObject map;

                            qint32 contactId = contact["id"].toInt();

                            map["id"]     = contactId;
                            map["type"]   = 0;
                            map["group"]  = "contact";
                            map["color"]  = contact["color"].toStr().c_str();
                            map["name"]   = name;
                            map["phone"]  = contact["phone"].toStr().c_str();
                            map["status"] = (qint32)m_backend->contactStatus(contactId);
                            map["inbox"]  = (qint32)m_backend->store()->numInboxMessages(contactId);

                            items.append(map);
                        }
                    });
                }
            });

            emit updateView(items);

            emit m_backend->invokeCallback(callback);
        });
    }
}

/**
 * @brief ContactModel::clearItems
 */

void ContactModel::clearItems()
{
    beginResetModel();

    m_items = QJsonArray();

    endResetModel();
}

/**
 * @brief ContactModel::onUpdateView
 * @param items
 */

void ContactModel::onUpdateView(const QJsonArray &items)
{
    beginResetModel();

    m_items = items;

    endResetModel();
}

/**
 * @brief ContactModel::roleNames
 * @return
 */

QHash<int, QByteArray> ContactModel::roleNames() const
{
    QHash<int, QByteArray> roles;

    roles[IdRole]      = "contactId";
    roles[TypeRole]    = "contactType";
    roles[GroupRole]   = "contactGroup";
    roles[ColorRole]   = "contactColor";
    roles[NameRole]    = "contactName";
    roles[PhoneRole]   = "contactPhone";
    roles[StatusRole]  = "contactStatus";
    roles[InboxRole]   = "contactInbox";
    roles[AddCodeRole] = "contactAddCode";

    return roles;
}

// ============================================================ //
