
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

#ifndef IMAGESERVICE_H
#define IMAGESERVICE_H

#include <QThreadPool>
#include <QRunnable>
#include <QMutex>
#include <QQueue>
#include <QJSValue>
#include <QQuickImageProvider>

#include <Zway/util/exif.h>

using namespace Zway;

// ============================================================ //

class BackendBase;

class ImageService : public QObject
{
    Q_OBJECT

public:

    enum {
        SOURCE_FILE_SYSTEM = 1,
        SOURCE_LOCAL_STORE,
        SOURCE_REMOTE_STORE
    };

private:

    class Task
    {
    public:

        Task() {}

        Task(const QString &url,
             const QVariant &data = QVariant(),
             const QJSValue &callback = QJSValue())
            : m_url(url),
              m_data(data),
              m_callback(callback) {}

        QString m_url;

        QVariant m_data;

        QJSValue m_callback;
    };

    class Batch
    {
    public:

        Batch() {}

        Batch(const QJSValue &callback = QJSValue())
            : m_callback(callback) {}

        QJSValue m_callback;

        QList<Task> m_tasks;
    };

    class LoadImageRunnable : public QRunnable
    {
    public:

        LoadImageRunnable(ImageService *service, const Task &task);

        void run();

    private:

        ImageService *m_service;

        Task m_task;
    };

    class LoadBatchRunnable : public QRunnable
    {
    public:

        LoadBatchRunnable(ImageService *service, const Batch &batch);

        void run();

    private:

        ImageService *m_service;

        Batch m_batch;
    };

public:

    class Provider : public QQuickImageProvider
    {
    public:

        Provider(QMap<QString, QImage> &images, QMutex &imagesMutex);

        QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize);

    private:

        QMap<QString, QImage> &m_images;

        QMutex &m_imagesMutex;
    };

public:

    static ImageService *instance() { return _inst; }

    static bool startup(BackendBase* backend);

    static void cleanup();

    Q_INVOKABLE void loadImage(
            const QString &url,
            const QVariant &data = QVariant(),
            const QJSValue &callback = QJSValue());

    Q_INVOKABLE void loadBatch(
            const QVariant &items,
            const QJSValue &callback = QJSValue());

    Provider *createImageProvider();

private:

    static ImageService *_inst;

    explicit ImageService(BackendBase *backend);

    bool hasImage(const Task &task);

    bool loadImage(const Task &task);


    QImage loadImageFileSystem(const QString& path);

    QImage loadImageLocalStore(uint64_t blobId);

    QImage processImageExif(const QImage &image, Exif &exif);


    QImage createThumb(const QImage &image, qint32 size);


signals:

    void taskEvent(bool err, const QString &url, const QVariant &data, const QJSValue &callback);

    void batchEvent(const QJSValue &callback);

public slots:

    void onTaskEvent(bool err, const QString &url, const QVariant &data, const QJSValue &callback);

    void onBatchEvent(const QJSValue &callback);

private:

    QThreadPool m_threadPool;

    QMap<QString, QImage> m_images;

    QMutex m_imagesMutex;

    BackendBase *m_backend;
};

// ============================================================ //

#endif // IMAGESERVICE_H
