
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

#ifndef ANDROID_HOOKS_H
#define ANDROID_HOOKS_H

#include <jni.h>
#include "android/backend.h"

#include <QAndroidJniObject>
#include <QJsonDocument>
#include <QJsonObject>

namespace Android {

// ============================================================ //

/**
 * @brief activityCallback
 * @param env
 * @param obj
 * @param id
 * @param data
 */

void activityCallback(JNIEnv *env, jobject obj, jint id, jstring data)
{
    Q_UNUSED(env)
    Q_UNUSED(obj)

    if (Backend::instance()) {

        QString json = QAndroidJniObject(data).toString();

        QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8());

        emit (Backend::instance())->nativeCallback(id, doc.object());
    }
}

/**
 * @brief registerActivityNatives
 * @param env
 */

void registerActivityNatives(JNIEnv *env)
{
    jclass cls = env->FindClass("de/atomicode/zway/ZwayActivity");

    JNINativeMethod natives[] {
        { "nativeCallback", "(ILjava/lang/String;)V", (void*)&activityCallback }
    };

    env->RegisterNatives(cls, natives, 1);

    env->DeleteLocalRef(cls);
}

/**
 * @brief sendFcmTokenToServer
 * @param env
 * @param obj
 * @param id
 * @param data
 */

void sendFcmTokenToServer(JNIEnv *env, jobject obj, jstring data)
{
    Q_UNUSED(env)
    Q_UNUSED(obj)

    QString token = QAndroidJniObject(data).toString();

    if (Backend::instance()) {

        QJsonObject obj = {
            {"fcmToken", token}
        };

        emit (Backend::instance())->nativeCallback(2000, obj);
    }
    else {

        // ...
    }
}

/**
 * @brief registerServiceNatives
 * @param env
 */

void registerServiceNatives(JNIEnv *env)
{
    jclass cls = env->FindClass("de/atomicode/zway/ZwayFirebaseInstanceService");

    JNINativeMethod natives[] {
        { "sendRegistrationToServer", "(Ljava/lang/String;)V", (void*)&sendFcmTokenToServer }
    };

    env->RegisterNatives(cls, natives, 1);

    env->DeleteLocalRef(cls);
}

}

/**
 * @brief JNI_OnLoad
 * @param vm
 * @param reserved
 * @return
 */

jint JNI_OnLoad(JavaVM* vm, void* reserved)
{
    Q_UNUSED(reserved)

    JNIEnv* env = nullptr;

    if (!vm->GetEnv((void**)&env, JNI_VERSION_1_6)) {

        Android::registerActivityNatives(env);

        Android::registerServiceNatives(env);
    }

    return JNI_VERSION_1_6;
}

// ============================================================ //

#endif
