
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

#include "imageservice.h"
#include "backendbase.h"

#include <QUrlQuery>

#include <Zway/memorybuffer.h>
#include <Zway/store.h>

// ============================================================ //

ImageService *ImageService::_inst = nullptr;

/**
 * @brief ImageService::startup
 * @param client
 * @return
 */

bool ImageService::startup(BackendBase *backend)
{
    if (_inst) {

        return false;
    }

    // create instance

    _inst = new ImageService(backend);

    return true;
}

/**
 * @brief ImageService::cleanup
 */

void ImageService::cleanup()
{
    if (_inst) {

        // wait for all runnables to complete (what about pending batches?)

        _inst->m_threadPool.waitForDone();

        // kill instance

        delete _inst;

        _inst = nullptr;
    }
}

/**
 * @brief ImageService::loadImage
 * @param path
 * @param thumbSize
 * @param source
 * @param cache
 * @param data
 * @param callback
 */

void ImageService::loadImage(const QString &url, const QVariant &data, const QJSValue &callback)
{
    Task task(url, data, callback);

    if (hasImage(task)) {

        emit taskEvent(false, task.m_url, data, callback);
    }
    else {

        m_threadPool.start(new LoadImageRunnable(this, task));
    }
}

/**
 * @brief ImageService::loadBatch
 * @param items
 * @param callback
 */

void ImageService::loadBatch(const QVariant &items, const QJSValue &callback)
{
    Batch batch(callback);

    for (QVariant &item : items.toList()) {

        QVariantMap map = item.toMap();

        QString url = map["url"].toString();

        QJSValue callback = ((BackendBase*)parent())->engine()->toScriptValue(map["callback"]);

        batch.m_tasks.append(Task(url, map["data"], callback));
    }

    m_threadPool.start(new LoadBatchRunnable(this, batch));
}

/**
 * @brief ImageService::createImageProvider
 * @return
 */

ImageService::Provider *ImageService::createImageProvider()
{
    Provider *prov = new Provider(m_images, m_imagesMutex);

    return prov;
}

/**
 * @brief ImageService::ImageService
 * @param parent
 */

ImageService::ImageService(BackendBase *backend)
    : QObject(backend),
      m_threadPool(this),
      m_backend(backend)
{
    QObject::connect(this, &ImageService::taskEvent, this, &ImageService::onTaskEvent);

    QObject::connect(this, &ImageService::batchEvent, this, &ImageService::onBatchEvent);
}

/**
 * @brief ImageService::hasImage
 * @param task
 * @return
 */

bool ImageService::hasImage(const Task &task)
{
    QMutexLocker imagesLocker(&m_imagesMutex);

    return m_images.contains(task.m_url);
}

/**
 * @brief ImageService::loadImage
 * @param task
 * @return
 */

bool ImageService::loadImage(const Task &task)
{
    QImage img;

    QUrl url(task.m_url);

    QUrlQuery query(url);

    uint64_t blobId = query.queryItemValue("blobId").toULongLong();

    qint32 source = query.queryItemValue("source").toInt();

    qint32 thumbSize = query.queryItemValue("thumbSize").toInt();

    /*
    img = m_backend->loadThumbnail(url.path(), blobId, thumbSize);

    if (!img.isNull()) {

        QMutexLocker locker(&m_imagesMutex);

        m_images[task.m_url] = img;

        return true;
    }
    */

    if (source == SOURCE_FILE_SYSTEM) {

        img = loadImageFileSystem(url.path());
    }
    else
    if (source == SOURCE_LOCAL_STORE) {

        img = loadImageLocalStore(blobId);
    }

    if (!img.isNull()) {

        QMutexLocker locker(&m_imagesMutex);

        if (thumbSize > 0) {

            m_images[task.m_url] = createThumb(img, thumbSize);
        }
        else {

            m_images[task.m_url] = img;
        }

        return true;
    }

    return false;
}

/**
 * @brief ImageService::loadImageFileSystem
 * @param path
 * @return
 */

QImage ImageService::loadImageFileSystem(const QString &path)
{
    QFile f(path);

    if (f.open(QFile::ReadOnly)) {

        QByteArray data = f.readAll();

        if (!data.isEmpty()) {

            QImage img;

            if (img.loadFromData(data)) {

                Exif exif;

                if (exif.load((uint8_t*)data.constData(), data.size())) {

                    return processImageExif(img, exif);
                }

                return img;
            }
        }
    }

    return QImage();
}

/**
 * @brief ImageService::loadImageLocalStore
 * @param resourceId
 * @return
 */

QImage ImageService::loadImageLocalStore(uint64_t blobId)
{
    MemoryBuffer$ buf = ((BackendBase*)parent())->store()->getBlobData("blob3", blobId);

    if (buf) {

        QImage img;

        if (img.loadFromData(buf->data(), buf->size())) {

            Exif exif;

            if (exif.load(buf->data(), buf->size())) {

                return processImageExif(img, exif);
            }

            return img;
        }
    }

    return QImage();
}

/**
 * @brief ImageService::processImageExif
 * @param image
 * @return
 */

QImage ImageService::processImageExif(const QImage &image, Exif &exif)
{
    switch (exif.getShortValue(EXIF_TAG_ORIENTATION)) {

        case 1:
            // top left side
            // do nothing
            break;

        case 2:
            // top right side
            // mirror horizontally
            return image.mirrored(true, false);

        case 3:
            // bottom right side
            // mirror horizontally and vertically
            return image.mirrored(true);

        case 4:
            // bottom left side
            // mirror vertically
            return image.mirrored(false);

        case 5:
            // left side top
            // rotate 90° cw and mirror horizontally
            return image.transformed(QMatrix().rotate(90)).mirrored(true, false);

        case 6:
            // right side top
            // rotate 90° cw
            return image.transformed(QMatrix().rotate(90));

        case 7:
            // right side bottom
            // rotate 90° ccw and mirror horizontally
            return image.transformed(QMatrix().rotate(-90)).mirrored(true, false);

        case 8:
            // left side bottom
            // rotate 90° ccw
            return image.transformed(QMatrix().rotate(-90));
    }

    return image;
}

/**
 * @brief ImageService::createThumb
 * @param image
 * @param size
 * @return
 */

QImage ImageService::createThumb(const QImage &image, qint32 size)
{
    QImage img;

    qint32 thumbSize = size * ((BackendBase*)parent())->dp();

    if (image.width() > thumbSize || image.height() > thumbSize) {

        if (image.width() < image.height()) {

            img = image.scaledToWidth(thumbSize);
        }
        else {

            img = image.scaledToHeight(thumbSize);
        }
    }
    else {

        img = image;
    }

    return img;
}

/**
 * @brief ImageService::onTaskEvent
 * @param err
 * @param url
 * @param data
 * @param callback
 */

void ImageService::onTaskEvent(bool err, const QString &url, const QVariant &data, const QJSValue &callback)
{
    QJSValue cb(callback);

    if (cb.isCallable()) {

        QJSValueList args;

        args.append(err);

        args.append(url);

        args.append(m_backend->engine()->toScriptValue<QVariant>(data));

        cb.call(args);
    }
}

/**
 * @brief ImageService::onBatchEvent
 * @param callback
 */

void ImageService::onBatchEvent(const QJSValue &callback)
{
    QJSValue cb(callback);

    if (cb.isCallable()) {

        QJSValueList args;

        cb.call(args);
    }
}

// ============================================================ //

/**
 * @brief ImageService::LoadImageRunnable::LoadImageRunnable
 * @param service
 * @param task
 */

ImageService::LoadImageRunnable::LoadImageRunnable(ImageService *service, const Task &task)
    : QRunnable(),
      m_service(service),
      m_task(task)
{

}

/**
 * @brief ImageService::LoadImageRunnable::run
 */

void ImageService::LoadImageRunnable::run()
{
    emit m_service->taskEvent(!m_service->loadImage(m_task), m_task.m_url, m_task.m_data, m_task.m_callback);
}

// ============================================================ //

/**
 * @brief ImageService::LoadBatchRunnable::LoadBatchRunnable
 * @param service
 * @param batch
 */

ImageService::LoadBatchRunnable::LoadBatchRunnable(ImageService *service, const Batch &batch)
    : QRunnable(),
      m_service(service),
      m_batch(batch)
{

}

/**
 * @brief ImageService::LoadBatchRunnable::run
 */

void ImageService::LoadBatchRunnable::run()
{
    for (Task &task : m_batch.m_tasks) {

        emit m_service->taskEvent(!m_service->loadImage(task), task.m_url, task.m_data, task.m_callback);
    }

    emit m_service->batchEvent(m_batch.m_callback);
}

// ============================================================ //

/**
 * @brief ImageService::Provider::Provider
 * @param images
 * @param mutex
 */

ImageService::Provider::Provider(
        QMap<QString, QImage> &images,
        QMutex &imagesMutex)
    : QQuickImageProvider(Image),
      m_images(images),
      m_imagesMutex(imagesMutex)
{

}

/**
 * @brief ImageService::Provider::requestImage
 * @param id
 * @param size
 * @param requestedSize
 * @return
 */

QImage ImageService::Provider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(requestedSize)

    QImage img;

    QUrl url(id);
    QUrlQuery query(url);

    uint64_t blobId = query.queryItemValue("blobId").toULongLong();

    qint32 thumbSize = query.queryItemValue("thumbSize").toInt();

    qint32 async = query.queryItemValue("async").toInt();

    qint32 cache = query.queryItemValue("cache").toInt();

    {
        QMutexLocker imagesLocker(&m_imagesMutex);

        if (m_images.contains(id)) {

            if (async == 1) {

                img = cache == 1 ? m_images[id] : m_images.take(id);
            }
            else {

                img = m_images[id];
            }
        }
    }

    /*
    if (img.isNull()) {

        img = m_backend->loadThumbnail(url.path(), blobId, thumbSize);
    }
    */

    if (img.isNull()) {

        if (async == 0 && img.isNull()) {

            QImage tmp;

            qint32 source = query.queryItemValue("source").toInt();

            if (source == SOURCE_FILE_SYSTEM) {

                tmp = ImageService::instance()->loadImageFileSystem(url.path());
            }
            else
            if (source == SOURCE_LOCAL_STORE) {

                tmp = ImageService::instance()->loadImageLocalStore(blobId);
            }

            if (!tmp.isNull()) {

                if (thumbSize > 0) {

                    img = ImageService::instance()->createThumb(tmp, thumbSize);
                }
                else {

                    img = tmp;
                }
            }
        }
    }

    if (!img.isNull() && size) {

        size->setWidth(img.width());
        size->setHeight(img.height());
    }

    return img;
}

// ============================================================ //
