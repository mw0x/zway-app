
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

#include "filesystemmodel.h"
#include "backendbase.h"

#include <QDir>

#include <Zway/memorybuffer.h>
#include <Zway/ubj/store/blob.h>
#include <Zway/store.h>

// ============================================================ //

/**
 * @brief FileSystemModel::FileSystemModel
 * @param backend
 */

FileSystemModel::FileSystemModel(BackendBase *backend) :
    QAbstractListModel(backend),
    m_backend(backend),
    m_numItemsTotal(0)
{

#ifdef Q_OS_ANDROID

    m_initialDir = "/sdcard/";

#else

    m_initialDir = QDir::homePath();

#endif

}

/**
 * @brief FileSystemModel::rowCount
 * @param parent
 * @return
 */

int FileSystemModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)

    return m_items.size();
}

/**
 * @brief FileSystemModel::data
 * @param index
 * @param role
 * @return
 */

QVariant FileSystemModel::data(const QModelIndex &index, int role) const
{
    if (index.row() < 0 || index.row() >= m_items.size()) {

        return QVariant();
    }

    const QFileInfo &item = m_items[index.row()];

    switch (role) {
        case IdRole:
            return item.absoluteFilePath();
        case TypeRole:
            if (item.isDir()) {
                return 1;
            }
            else
            if (item.isFile()) {
                return 2;
            }
            break;
        case NameRole:
            return item.fileName();
        case SizeRole:
            return item.size();
        case OriginRole:
            return 1;
    }

    return QVariant();
}

/**
 * @brief FileSystemModel::getItemData
 * @param index
 * @return
 */

QVariant FileSystemModel::getItemData(qint32 index) const
{
    if (index < 0 || index >= m_items.size()) {

        return QVariant();
    }

    QVariantMap res;

    const QFileInfo &item = m_items[index];

    if (item.isDir()) {

        res["type"] = 1;
    }
    else
    if (item.isFile()) {

        res["type"] = 2;
    }

    res["id"]     = item.absoluteFilePath();
    res["path"]   = item.absoluteFilePath();
    res["name"]   = item.fileName();
    res["size"]   = item.size();
    res["origin"] = 1;

    return res;
}

/**
 * @brief FileSystemModel::cd
 * @param dir
 * @return
 */

bool FileSystemModel::cd(const QString &dir)
{
    QDir d = QDir(dir.length() ? dir : (m_currentDir.length() ? m_currentDir : m_initialDir));

    if (d.exists()) {

        clear();

        m_currentDir = d.absolutePath();

        m_itemsFull = d.entryInfoList(QDir::NoFilter, QDir::DirsFirst);

        m_itemsFull.removeFirst();

        m_itemsFull.removeFirst();

        m_numItemsTotal = m_itemsFull.size();

        return true;
    }

    return false;
}

/**
 * @brief FileSystemModel::moreItems
 * @param numItems
 * @param callback
 * @return
 */

bool FileSystemModel::moreItems(qint32 numItems, const QJSValue &callback)
{
    if (!m_itemsFull.empty()) {

        qint32 num = numItems;

        if (num > m_itemsFull.size()) {

            num = m_itemsFull.size();
        }

        beginInsertRows(QModelIndex(), m_items.size(), m_items.size() + num - 1);

        QFileInfoList::iterator a = m_itemsFull.begin();
        QFileInfoList::iterator b = m_itemsFull.begin() + num;

        std::move(a, b, std::back_inserter(m_items));

        m_itemsFull.erase(a, b);

        endInsertRows();

        // invoke callback if any

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
 * @brief FileSystemModel::currentDir
 * @return
 */

QString FileSystemModel::currentDir()
{
    return m_currentDir;
}

/**
 * @brief FileSystemModel::numItemsTotal
 * @return
 */

quint32 FileSystemModel::numItemsTotal()
{
    return m_numItemsTotal;
}

/**
 * @brief FileSystemModel::clear
 */

void FileSystemModel::clear()
{
    beginResetModel();

    m_itemsFull.clear();

    m_items.clear();

    m_currentDir.clear();

    m_numItemsTotal = 0;

    endResetModel();
}

/**
 * @brief FileSystemModel::createDirectory
 * @param name
 * @param parent
 * @param callback
 */

void FileSystemModel::createDirectory(const QString &name, const QString &parent, const QJSValue &callback)
{
    LambdaRunnable::start([this, name, parent, callback] {

        QDir d(m_currentDir);

        if (!d.mkdir(name)) {

        }

        emit m_backend->invokeCallback(callback);

    });
}

/**
 * @brief FileSystemModel::deleteItems
 * @param items
 * @param callback
 */

void FileSystemModel::deleteItems(const QVariantList &items, const QJSValue &callback)
{
    LambdaRunnable::start([this, items, callback] {

        for (QVariant it : items) {

            QFileInfo info(it.toString());

            if (info.isDir()) {

                QDir d(it.toString());

                if (!d.removeRecursively()) {

                }
            }
            else
            if (info.isFile()) {

                if (!QFile::remove(info.absoluteFilePath())) {

                }
            }
        }

        emit m_backend->invokeCallback(callback);
    });
}

/**
 * @brief FileSystemModel::pasteFromFileSystem
 * @param items
 * @param dst
 * @param callback
 */

void FileSystemModel::pasteFromFileSystem(const QVariantList &items, const QString &dst, const QJSValue &callback)
{
    LambdaRunnable::start([this, items, dst, callback] {

        QFileInfo info(dst);

        if (!info.isDir()) {

            // TODO we need to pass an error here

            emit m_backend->invokeCallback(callback);

            return;
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

                if (!copyDirectory(info.absoluteFilePath(), dst, true)) {

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
 * @brief FileSystemModel::pasteFromLocalStore
 * @param items
 * @param dst
 * @param callback
 */

void FileSystemModel::pasteFromLocalStore(const QVariantList &items, const QString &dst, const QJSValue &callback)
{
    LambdaRunnable::start([this, items, dst, callback] {

        QFileInfo info(dst);

        if (!info.isDir()) {

            //emit m_client->invokeCallback(callback);

            return;
        }

        for (QVariant it : items) {

            UBJ::Object node;

            if (m_backend->store()->query("vfs", UBJ_OBJ("rowid" << (uint64_t)it.toULongLong()), &node, {}, {"type"})) {

                if (node["type"].toInt() == Store::File) {

                    if (!copyResource(it.toULongLong(), dst)) {

                        // TODO pass error to callback

                        //emit m_client->invokeCallback(callback);

                        //return;
                    }
                }
                else
                if (node["type"].toInt() == Store::Directory) {

                    if (!copyDirectory(it.toULongLong(), dst)) {

                        // TODO pass error to callback

                        //emit m_client->invokeCallback(callback);

                        //return;
                    }
                }
            }
        }

        emit m_backend->invokeCallback(callback);
    });
}

/**
 * @brief FileSystemModel::copyFile
 * @param src
 * @param dst
 * @return
 */

bool FileSystemModel::copyFile(const QString &src, const QString &dst)
{
    QDir dstDir(dst);

    QFileInfo srcInfo(src);

    // check whether file with same name already exists

    QFileInfo dstInfo(dstDir.filePath(srcInfo.fileName()));

    if (dstInfo.isFile()) {

        return true;
    }

    // copy file

    if (!QFile::copy(src, dstInfo.absoluteFilePath())) {

        return false;
    }

    return true;
}

/**
 * @brief FileSystemModel::copyDirectory
 * @param src
 * @param dst
 * @param recursive
 * @return
 */

bool FileSystemModel::copyDirectory(const QString &src, const QString &dst, bool recursive)
{
    if (src == dst) {

        return false;
    }

    QDir srcDir(src);

    QString name = srcDir.dirName();

    QDir dstDir(dst);

    if (dstDir.cd(name)) {

        return false;
    }

    if (!(dstDir.mkdir(name) && dstDir.cd(name))) {

        return false;
    }

    QFileInfoList files = srcDir.entryInfoList(QDir::NoFilter, QDir::DirsFirst);

    for (auto &file : files) {

        if (file.fileName() == "." || file.fileName() == "..") {

            continue;
        }

        if (file.isFile()) {

            if (!copyFile(file.absoluteFilePath(), dstDir.absolutePath())) {

                return false;
            }
        }
        else
        if (file.isDir()) {

            if (!copyDirectory(file.absoluteFilePath(), dstDir.absolutePath(), recursive)) {

                return false;
            }
        }
    }

    return true;
}

/**
 * @brief FileSystemModel::copyResource
 * @param src
 * @param dst
 * @return
 */

bool FileSystemModel::copyResource(uint64_t src, const QString &dst)
{
    UBJ::Object node;

    if (!m_backend->store()->query("vfs", UBJ_OBJ("rowid" << src << "type" << Store::File), &node, {}, {"name", "data"})) {

        return false;
    }

    QFileInfo info(QDir(dst).filePath(node["name"].toStr().c_str()));

    if (info.isFile()) {

        return true;
    }

    QFile file(info.absoluteFilePath());

    if (!file.open(QFile::WriteOnly)) {

        return false;
    }

    m_backend->store()->readBlob("blob3", node["data"].toLong(), [&info, &file] (bool error, UBJ::Store::Blob$ blob) {

        if (!error) {

            uint32_t blockSize = 4096;

            uint32_t bytesWritten = 0;

            MemoryBuffer$ buf = MemoryBuffer::create(nullptr, blockSize);

            if (!buf) {

                return;
            }

            while (bytesWritten < blob->size()) {

                uint32_t bytesToWrite = blockSize;

                if (blob->size() - bytesWritten < blockSize) {

                    bytesToWrite = blob->size() - bytesWritten;
                }

                blob->read(buf, bytesToWrite, bytesWritten);

                file.write((char*)buf->data(), bytesToWrite);

                bytesWritten += bytesToWrite;

                buf->clear();
            }
        }
    });

    file.close();

    return true;
}

/**
 * @brief FileSystemModel::copyDirectory
 * @param src
 * @param dst
 * @param recursive
 * @return
 */

bool FileSystemModel::copyDirectory(uint64_t src, const QString &dst, bool recursive)
{
    UBJ::Object node;

    if (!m_backend->store()->query("vfs", UBJ_OBJ("rowid" << src), &node, {}, {"name"})) {

        return false;
    }

    QString name = node["name"].toStr().c_str();

    QDir dir(dst);

    if (dir.cd(name)) {

        return false;
    }

    if (!(dir.mkdir(name) && dir.cd(name))) {

        return false;
    }

    std::list<UBJ::Object> nodes;

    m_backend->store()->query("vfs", UBJ_OBJ("parent" << src), nodes, {}, {"rowid", "type"});

    for (auto &node : nodes) {

        if (node["type"].toInt() == Store::File) {

            if (!copyResource(node["rowid"].toLong(), dir.absolutePath())) {

                //return false;
            }
        }
        else
        if (node["type"].toInt() == Store::Directory) {

            if (!copyDirectory(node["rowid"].toLong(), dir.absolutePath(), recursive)) {

                //return false;
            }
        }
    }

    return true;
}

/**
 * @brief FileSystemModel::roleNames
 * @return
 */

QHash<int, QByteArray> FileSystemModel::roleNames() const
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
