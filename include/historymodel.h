
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

#ifndef HISTORYMODEL_H
#define HISTORYMODEL_H

#include <QAbstractListModel>
#include <QJSValue>

#include <Zway/message/message.h>

using namespace Zway;

class BackendBase;

// ============================================================ //

/**
 * @brief The HistoryModel class
 */

class HistoryModel : public QAbstractListModel
{
    Q_OBJECT

public:

    enum Roles {
        IdRole = Qt::UserRole + 1,
        SrcRole,
        DstRole,
        StatusRole,
        TimeRole,
        TextRole
    };

    explicit HistoryModel(BackendBase *backend, quint32 historyId);

    int rowCount(const QModelIndex &parent = QModelIndex()) const;

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;

    Q_INVOKABLE QVariant get(int index);

    Q_INVOKABLE void append(const QVariantMap &message);

    Q_INVOKABLE void update(const QVariantMap &message);

    Q_INVOKABLE qint32 messageIndex(quint32 id);

signals:

    void updateView(const QVariantList &items);

public slots:

    void updateItems(const QJSValue &callback = QJSValue());

    void clearItems();

    void onUpdateView(const QVariantList &items);

protected:

    QVariantMap messageToVariant(Message$ message);

    QVariantMap resourceToVariant(Resource$ resource);

    QHash<int, QByteArray> roleNames() const;

private:

    BackendBase *m_backend;

    quint32 m_historyId;

    QVariantList m_items;

    QMap<uint32_t, uint32_t> m_indexes;
};

// ============================================================ //

#endif // HISTORYMODEL_H
