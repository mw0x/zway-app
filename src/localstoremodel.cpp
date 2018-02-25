
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

#include "localstoremodel.h"
#include "backendbase.h"

#include <QRegularExpression>
#include <QFileInfo>
#include <QDir>

#include <Zway/memorybuffer.h>
#include <Zway/message/resource.h>
#include <Zway/ubj/store/blob.h>
#include <Zway/store.h>

// ============================================================ //

/**
 * @brief LocalStoreModel::LocalStoreModel
 * @param backend
 */

LocalStoreModel::LocalStoreModel(BackendBase *backend) :
    QAbstractListModel(backend),
    m_backend(backend),
    m_currentDir(0),
    m_numItemsTotal(0)
{

}

/**
 * @brief LocalStoreModel::rowCount
 * @param parent
 * @return
 */

int LocalStoreModel::rowCount(const QModelIndex &parent) const {

    Q_UNUSED(parent)

    return m_items.size();
}

/**
 * @brief LocalStoreModel::data
 * @param index
 * @param role
 * @return
 */

QVariant LocalStoreModel::data(const QModelIndex &index, int role) const {

    if (index.row() < 0 || index.row() > m_items.size()) {

        return QVariant();
    }

    const QVariantMap &item = m_items[index.row()];

    switch (role) {
        case IdRole:
            return item["id"];
        case TypeRole:
            return item["type"];
        case NameRole:
            return item["name"];
        case SizeRole:
            return item["size"];
        case OriginRole:
            return 2;
    }

    return QVariant();
}

/**
 * @brief LocalStoreModel::getItemData
 * @param index
 * @return
 */

QVariant LocalStoreModel::getItemData(qint32 index)
{
    if (index >= 0 && index < m_items.size()) {

        return m_items[index];
    }

    return QVariant();
}

/**
 * @brief LocalStoreModel::cd
 * @param dir
 * @return
 */

bool LocalStoreModel::cd(quint32 dir)
{
    Store$ store = m_backend->store();

    if (dir) {

        if (!store->count("vfs", UBJ_OBJ("rowid" << dir))) {

            return false;
        }
    }

    clear();

    m_currentDir = dir;

    std::list<UBJ::Object> items;

    store->query("vfs", UBJ_OBJ("parent" << dir << "type" << Store::Directory), items, UBJ_OBJ("name" << 1), UBJ_ARR("rowid" << "*"));

    store->query("vfs", UBJ_OBJ("parent" << dir << "type" << Store::File), items, UBJ_OBJ("name" << 1), UBJ_ARR("rowid" << "*"));

    for (auto &it : items) {

        QVariantMap map;

        map["id"]   = it["rowid"].toInt();
        map["type"] = it["type"].toInt();
        map["name"] = it["name"].toStr().c_str();
        map["data"] = it["data"].toInt();
        map["origin"] = 2;

        m_itemsFull.append(map);
    }

    m_numItemsTotal = m_itemsFull.size();

    return true;
}

/**
 * @brief LocalStoreModel::moreItems
 * @param numItems
 * @param callback
 * @return
 */

bool LocalStoreModel::moreItems(qint32 numItems, const QJSValue &callback)
{
    if (!m_itemsFull.empty()) {

        qint32 num = numItems;

        if (num > m_itemsFull.size()) {

            num = m_itemsFull.size();
        }

        beginInsertRows(QModelIndex(), m_items.size(), m_items.size() + num - 1);

        QList<QVariantMap>::iterator a = m_itemsFull.begin();
        QList<QVariantMap>::iterator b = m_itemsFull.begin() + num;

        std::move(a, b, std::back_inserter(m_items));

        m_itemsFull.erase(a, b);

        endInsertRows();

        QJSValue cb(callback);

        if (cb.isCallable()) {

            QJSValueList args;

            args.append(num);

            cb.call(args);
        }

        return true;
    }

    return false;
}

/**
 * @brief LocalStoreModel::currentDir
 * @return
 */

quint32 LocalStoreModel::currentDir()
{
    return m_currentDir;
}

/**
 * @brief LocalStoreModel::numItemsTotal
 * @return
 */

quint32 LocalStoreModel::numItemsTotal()
{
    return m_numItemsTotal;
}

/**
 * @brief LocalStoreModel::clear
 */

void LocalStoreModel::clear()
{
    beginResetModel();

    m_currentDir = 0;

    m_itemsFull.clear();

    m_items.clear();

    endResetModel();
}

/**
 * @brief LocalStoreModel::createDirectory
 * @param name
 * @param parent
 * @param callback
 */

void LocalStoreModel::createDirectory(const QString &name, quint32 parent, const QJSValue &callback)
{
    LambdaRunnable::start([this, name, parent, callback] {

        if (!m_backend->store()->createVfsNode(Store::Directory, name.toStdString(), parent)) {

            // ...
        }

        emit m_backend->invokeCallback(callback);
    });
}

/**
 * @brief LocalStoreModel::deleteItems
 * @param items
 * @param callback
 */

void LocalStoreModel::deleteItems(const QVariantList &items, const QJSValue &callback)
{
    LambdaRunnable::start([this, items, callback] {

        for (QVariant it : items) {

            quint32 id = it.toUInt();

            if (!m_backend->store()->deleteVfsNode(id)) {

                // ...
            }
        }

        emit m_backend->invokeCallback(callback);
    });
}

/**
 * @brief LocalStoreModel::pasteFromFileSystem
 * @param items
 * @param dst
 * @param callback
 */

void LocalStoreModel::pasteFromFileSystem(const QVariantList &items, quint32 dst, const QJSValue &callback)
{
    LambdaRunnable::start([this, items, dst, callback] {

        // get dst node

        if (dst) {

            if (!m_backend->store()->count(
                        "vfs",
                        UBJ_OBJ(
                            "rowid" << dst <<
                            "type"  << Store::Directory))) {

                // TODO pass error to callback

                emit m_backend->invokeCallback(callback);

                return;
            }
        }

        // process items to paste

        for (QVariant it : items) {

            QFileInfo info(it.toString());

            if (info.isFile()) {

                if (!copyFile(info.absoluteFilePath(), dst)) {

                    // TODO pass error to callback

                    emit m_backend->invokeCallback(callback);

                    return;
                }
            }
            else
            if (info.isDir()) {

                if (!copyDirectory(info.absoluteFilePath(), dst)) {

                    // TODO pass error to callback

                    emit m_backend->invokeCallback(callback);

                    return;
                }
            }
        }

        emit m_backend->invokeCallback(callback);
    });
}

/**
 * @brief LocalStoreModel::pasteFromLocalStore
 * @param items
 * @param dst
 * @param callback
 */

void LocalStoreModel::pasteFromLocalStore(const QVariantList &items, quint32 dst, const QJSValue &callback)
{
    LambdaRunnable::start([this, items, dst, callback] {

        for (QVariant it : items) {

            UBJ::Object node;

            if (m_backend->store()->query("vfs", UBJ_OBJ("rowid" << (uint64_t)it.toULongLong()), &node, {}, {"type"})) {

                if (node["type"].toInt() == Store::File) {

                    if (!copyResource(it.toULongLong(), dst)) {

                        // TODO pass error to callback

                        //emit m_backend->invokeCallback(callback);

                        //return;
                    }
                }
                else
                if (node["type"].toInt() == Store::Directory) {

                    if (!copyDirectory(it.toULongLong(), dst)) {

                        // TODO passs error to callback

                        //emit m_backend->invokeCallback(callback);

                        //return;
                    }
                }
            }
        }

        emit m_backend->invokeCallback(callback);
    });
}

/**
 * @brief LocalStoreModel::copyFile
 * @param src
 * @param dst
 * @return
 */

bool LocalStoreModel::copyFile(const QString &src, uint64_t dst)
{
    QFileInfo info(src);

    Resource$ file = FileSystemResource::create(info.absoluteFilePath().toStdString());

    if (!file || !file->open()) {

        return false;
    }

    uint64_t blobId = m_backend->store()->createBlob("blob3", file->size());

    if (!blobId) {

        return false;
    }

    m_backend->store()->writeBlob("blob3", blobId, [&info, &file] (bool error, UBJ::Store::Blob$ blob) {

        if (!error) {

            uint32_t blockSize = 4096;

            uint32_t bytesWritten = 0;

            MemoryBuffer$ buf = MemoryBuffer::create(nullptr, blockSize);

            if (!buf) {

                return;
            }

            while (bytesWritten < file->size()) {

                uint32_t bytesToWrite = blockSize;

                if (file->size() - bytesWritten < blockSize) {

                    bytesToWrite = file->size() - bytesWritten;
                }

                file->read(buf, bytesToWrite, bytesWritten);

                blob->write(buf, bytesToWrite, bytesWritten);

                bytesWritten += bytesToWrite;

                buf->clear();
            }
        }
    });

    if (!m_backend->store()->createVfsNode(
                Store::File,
                info.fileName().toStdString(),
                dst,
                UBJ_OBJ(
                    "size" << file->size() <<
                    "hash" << file->hash() <<
                    "data" << blobId))) {

        return false;
    }

    return true;
}

/**
 * @brief LocalStoreModel::copyDirectory
 * @param src
 * @param dst
 * @param recursive
 * @return
 */

bool LocalStoreModel::copyDirectory(const QString &src, uint64_t dst, bool recursive)
{
    QDir dir(src);

    if (m_backend->store()->count(
                "vfs",
                UBJ_OBJ(
                    "name"   << dir.dirName().toStdString() <<
                    "type"   << Store::Directory <<
                    "parent" << dst))) {

        return false;
    }

    uint64_t dirId = m_backend->store()->createVfsNode(Store::Directory, dir.dirName().toStdString(), dst);

    if (!dirId) {

        return false;
    }

    QFileInfoList files = dir.entryInfoList(QDir::NoFilter, QDir::DirsFirst);

    for (auto &file : files) {

        if (file.fileName() == "." || file.fileName() == "..") {

            continue;
        }

        if (file.isFile()) {

            if (!copyFile(file.absoluteFilePath(), dirId)) {

                return false;
            }
        }
        else
        if (file.isDir()) {

            if (!copyDirectory(file.absoluteFilePath(), dirId, recursive)) {

                return false;
            }
        }
    }

    return true;
}

/**
 * @brief LocalStoreModel::copyResource
 * @param src
 * @param dst
 * @return
 */

bool LocalStoreModel::copyResource(uint64_t src, uint64_t dst)
{
    UBJ::Object node;

    if (!m_backend->store()->query("vfs", UBJ_OBJ("rowid" << src), &node)) {

        return false;
    }

    if (m_backend->store()->count("vfs", UBJ_OBJ("name" << node["name"] << "parent" << dst))) {

        return false;
    }

    if (!m_backend->store()->createVfsNode(Store::File, node["name"].toStr(), dst, node)) {

        return false;
    }

    return true;
}

/**
 * @brief LocalStoreModel::copyDirectory
 * @param src
 * @param dst
 * @param recursive
 * @return
 */

bool LocalStoreModel::copyDirectory(uint64_t src, uint64_t dst, bool recursive)
{
    if (src == dst) {

        return false;
    }

    UBJ::Object node;

    if (!m_backend->store()->query("vfs", UBJ_OBJ("rowid" << src), &node)) {

        return false;
    }

    if (m_backend->store()->count("vfs", UBJ_OBJ("name" << node["name"] << "parent" << dst))) {

        return false;
    }

    uint64_t dirId = m_backend->store()->createVfsNode(Store::Directory, node["name"].toStr(), dst);

    if (!dirId) {

        return false;
    }

    std::list<UBJ::Object> nodes;

    m_backend->store()->query("vfs", UBJ_OBJ("parent" << src), nodes, {}, {"rowid", "type"});

    for (auto &node : nodes) {

        if (node["type"].toInt() == Store::File) {

            if (!copyResource(node["rowid"].toLong(), dirId)) {

                //return false;
            }
        }
        else
        if (node["type"].toInt() == Store::Directory) {

            if (!copyDirectory(node["rowid"].toLong(), dirId, recursive)) {

                //return false;
            }
        }
    }

    return true;
}

/**
 * @brief LocalStoreModel::roleNames
 * @return
 */

QHash<int, QByteArray> LocalStoreModel::roleNames() const
{
    QHash<int, QByteArray> roles;

    roles[IdRole]     = "itemId";
    roles[TypeRole]   = "type";
    roles[NameRole]   = "name";
    roles[SizeRole]   = "size";
    roles[OriginRole] = "origin";

    return roles;
}

// ============================================================ //
