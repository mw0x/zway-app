
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

#ifndef FILESYSTEMMODEL_H
#define FILESYSTEMMODEL_H

#include <QAbstractListModel>
#include <QJSValue>
#include <QFileInfoList>

class BackendBase;

// ============================================================ //

/**
 * @brief The FileSystemModel class
 */

class FileSystemModel : public QAbstractListModel
{
    Q_OBJECT

public:

    enum Roles {
        IdRole = Qt::UserRole + 1,
        TypeRole,
        NameRole,
        SizeRole,
        OriginRole
    };

    explicit FileSystemModel(BackendBase *backend = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const;

    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;

    Q_INVOKABLE QVariant getItemData(qint32 index) const;

    Q_INVOKABLE bool cd(const QString &dir = QString());

    Q_INVOKABLE bool moreItems(qint32 numItems, const QJSValue &callback = QJSValue());

    Q_INVOKABLE QString currentDir();

    Q_INVOKABLE quint32 numItemsTotal();

    Q_INVOKABLE void clear();

    Q_INVOKABLE void createDirectory(const QString &name, const QString &parent, const QJSValue &callback = QJSValue());

    Q_INVOKABLE void deleteItems(const QVariantList &items, const QJSValue &callback = QJSValue());

    Q_INVOKABLE void pasteFromFileSystem(const QVariantList &items, const QString& dst, const QJSValue &callback = QJSValue());

    Q_INVOKABLE void pasteFromLocalStore(const QVariantList &items, const QString& dst, const QJSValue &callback = QJSValue());

private:

    bool copyFile(const QString &src, const QString &dst);

    bool copyDirectory(const QString &src, const QString &dst, bool recursive = true);


    bool copyResource(uint64_t src, const QString &dst);

    bool copyDirectory(uint64_t src, const QString &dst, bool recursive = true);


    QHash<int, QByteArray> roleNames() const;

private:

    BackendBase *m_backend;

    QString m_initialDir;

    QString m_currentDir;

    quint32 m_numItemsTotal;

    QFileInfoList m_itemsFull;

    QFileInfoList m_items;
};

// ============================================================ //

#endif // FILESYSTEMMODEL_H
