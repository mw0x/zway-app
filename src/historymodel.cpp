
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

#include "historymodel.h"
#include "backendbase.h"

#include <QDebug>

// ============================================================ //

/**
 * @brief HistoryModel::HistoryModel
 * @param backend
 * @param historyId
 */

HistoryModel::HistoryModel(BackendBase *backend, quint32 historyId) :
    QAbstractListModel(backend),
    m_backend(backend),
    m_historyId(historyId)
{
    QObject::connect(this, &HistoryModel::updateView, this, &HistoryModel::onUpdateView);
}

/**
 * @brief HistoryModel::rowCount
 * @param parent
 * @return
 */

int HistoryModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)

    return m_items.size();
}

/**
 * @brief HistoryModel::data
 * @param index
 * @param role
 * @return
 */

QVariant HistoryModel::data(const QModelIndex &index, int role) const
{
    if (index.row() < 0 || index.row() > m_items.size()) {

        return QVariant();
    }

    const QVariantMap &item = m_items[m_items.size() - index.row() - 1].toMap();

    switch (role) {
        case IdRole:
            return item["id"];
        case SrcRole:
            return item["src"];
        case DstRole:
            return item["dst"];
        case StatusRole:
            return item["status"];
        case TimeRole:
            return item["time"];
        case TextRole:
            return item["text"];
    }

    return QVariant();
}

/**
 * @brief HistoryModel::get
 * @param index
 * @return
 */

QVariant HistoryModel::get(int index)
{
    if (index >= 0 && index < m_items.size()) {

        return m_items[m_items.size() - index - 1];
    }

    return QVariant();
}

/**
 * @brief HistoryModel::append
 * @param message
 */

void HistoryModel::append(const QVariantMap &message)
{
    beginInsertRows(QModelIndex(), 0, 0);

    m_items.append(message);

    m_indexes[message["id"].toUInt()] = m_items.size() - 1;

    endInsertRows();
}

/**
 * @brief HistoryModel::update
 * @param message
 */

void HistoryModel::update(const QVariantMap &message)
{
    quint32 messageId = message["id"].toUInt();

    if (m_indexes.find(messageId) != m_indexes.end()) {

        quint32 i = m_indexes[messageId];

        m_items[i] = message;

        QModelIndex modelIndex = index(m_items.size() - i - 1);

        emit dataChanged(modelIndex, modelIndex);
    }
}

/**
 * @brief HistoryModel::messageIndex
 * @param id
 * @return
 */

qint32 HistoryModel::messageIndex(quint32 id)
{
    if (m_indexes.contains(id)) {

        return m_indexes[id];
    }

    return -1;
}

/**
 * @brief HistoryModel::updateItems
 * @param callback
 */

void HistoryModel::updateItems(const QJSValue &callback)
{
    LambdaRunnable::start(
        [this, callback] {

            QVariantList items;

            for (auto &message : m_backend->store()->getMessages(m_historyId)) {

                QVariantMap item = messageToVariant(message);

                items.append(item);
            }

            emit updateView(items);

            emit m_backend->invokeCallback(callback);
        });
}

/**
 * @brief HistoryModel::clearItems
 */

void HistoryModel::clearItems()
{
    beginResetModel();

    m_items.clear();

    m_indexes.clear();

    endResetModel();
}

/**
 * @brief HistoryModel::onUpdateView
 * @param items
 */

void HistoryModel::onUpdateView(const QVariantList &items)
{
    beginResetModel();

    m_items = items;

    m_indexes.clear();

    auto index = 0;

    for (auto &item : m_items) {

        QVariantMap message = item.toMap();

        m_indexes[message["id"].toUInt()] = index++;
    }

    endResetModel();
}

/**
 * @brief HistoryModel::messageToVariant
 * @param message
 * @return
 */

QVariantMap HistoryModel::messageToVariant(MESSAGE message)
{
    QVariantMap msg;

    msg["id"]     = message->id();
    msg["src"]    = message->src();
    msg["dst"]    = message->dst();
    msg["status"] = message->status();
    msg["time"]   = message->time();
    msg["text"]   = message->text().c_str();

    QVariantList resources;

    for (uint32_t i=0; i<message->numResources(); ++i) {

        resources.append(resourceToVariant(message->resource(i)));
    }

    msg["resources"] = resources;

    return msg;
}

/**
 * @brief HistoryModel::resourceToVariant
 * @param resource
 * @return
 */

QVariantMap HistoryModel::resourceToVariant(RESOURCE resource)
{
    QVariantMap res;

    res["id"]   = resource->id();
    res["name"] = resource->name().c_str();
    res["size"] = (quint64)resource->size();
    res["type"] = resource->type();

    return res;
}

/**
 * @brief HistoryModel::roleNames
 * @return
 */

QHash<int, QByteArray> HistoryModel::roleNames() const
{
    QHash<int, QByteArray> roles;

    roles[IdRole]       = "messageId";
    roles[SrcRole]      = "messageSrc";
    roles[DstRole]      = "messageDst";
    roles[StatusRole]   = "messageStatus";
    roles[TimeRole]     = "messageTime";
    roles[TextRole]     = "messageText";

    return roles;
}

// ============================================================ //
