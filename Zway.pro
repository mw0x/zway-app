
## ============================================================ ##
##
##   d88888D db   d8b   db  .d8b.  db    db
##   YP  d8' 88   I8I   88 d8' `8b `8b  d8'
##      d8'  88   I8I   88 88ooo88  `8bd8'
##     d8'   Y8   I8I   88 88~~~88    88
##    d8' db `8b d8'8b d8' 88   88    88
##   d88888P  `8b8' `8d8'  YP   YP    YP
##
##   open-source, cross-platform, crypto-messenger
##
##   Copyright (C) 2017 Marc Weiler
##
##   This program is free software: you can redistribute it and/or modify
##   it under the terms of the GNU General Public License as published by
##   the Free Software Foundation, either version 3 of the License, or
##   (at your option) any later version.
##
##   This program is distributed in the hope that it will be useful,
##   but WITHOUT ANY WARRANTY; without even the implied warranty of
##   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##   GNU General Public License for more details.
##
##   You should have received a copy of the GNU General Public License
##   along with this program. If not, see <http://www.gnu.org/licenses/>.
##
## ============================================================ ##

TEMPLATE = app

QT += qml quick

CONFIG += c++11

linux-g++ {
QMAKE_LFLAGS += -static-libgcc
QMAKE_LFLAGS += -static-libstdc++
}

QMAKE_LFLAGS_WINDOWS += -static
QMAKE_LFLAGS_WINDOWS += -Wl,-subsystem,console

INCLUDEPATH += include

## ============================================================ ##

SOURCES += \
    src/backendbase.cpp \
    src/imageservice.cpp \
    src/contactmodel.cpp \
    src/historymodel.cpp \
    src/filesystemmodel.cpp \
    src/localstoremodel.cpp \
    src/main.cpp

HEADERS += \
    include/backendbase.h \
    include/imageservice.h \
    include/contactmodel.h \
    include/historymodel.h \
    include/filesystemmodel.h \
    include/localstoremodel.h

## ============================================================ ##

unix:!android {

SOURCES += \
    src/desktop/backend.cpp

HEADERS += \
    include/desktop/backend.h

}

## ============================================================ ##

android {

QT += androidextras

SOURCES += \
    src/android/backend.cpp

HEADERS += \
    include/android/backend.h \
    include/android/hooks.h \

DISTFILES += \
    android/AndroidManifest.xml \
    android/google-services.json \
    android/gradle/wrapper/gradle-wrapper.jar \
    android/gradle/wrapper/gradle-wrapper.properties \
    android/gradlew \
    android/gradlew.bat \
    android/res/values/libs.xml \
    android/build.gradle \
    android/res/values/styles.xml \
    android/res/values-v19/styles.xml \
    android/res/values-v21/styles.xml \
    android/src/de/atomicode/zway/ZwayActivity.java \
    android/src/de/atomicode/zway/ZwayFirebaseInstanceService.java \
    android/src/de/atomicode/zway/ZwayFirebaseMessagingService.java \
    android/src/org/qtproject/qt5/android/bindings/QtActivityLoader.java

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android

}

## ============================================================ ##

include(libzway.pri)

RESOURCES += \
    qml.qrc \
    res.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# The following define makes your compiler emit warnings if you use
# any feature of Qt which as been marked deprecated (the exact warnings
# depend on your compiler). Please consult the documentation of the
# deprecated API in order to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

# You can also make your code fail to compile if you use deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

## ============================================================ ##
