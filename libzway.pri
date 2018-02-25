
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
##   Copyright (C) 2018 Marc Weiler
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

LIBZWAY_ROOT = $$(LIBZWAY_ROOT)

LIBZWAY_PATH = $$(LIBZWAY_PATH)

DEPS_PATH = $$LIBZWAY_ROOT/deps/install

INCLUDEPATH += $$LIBZWAY_ROOT/include

linux:!android {

    contains(QT_ARCH, x86_64): {
        DEPS_PATH = $$DEPS_PATH/linux_64
    } else {
        DEPS_PATH = $$DEPS_PATH/linux_32
    }

    PRE_TARGETDEPS += $$LIBZWAY_PATH/libzway.a

    INCLUDEPATH += $$DEPS_PATH/include
    DEPENDPATH  += $$DEPS_PATH/include
    LIBS        += -L$$LIBZWAY_PATH -L$$DEPS_PATH/lib -lzway -lgnutls -lhogweed -lnettle -lgmp -lsqlite3 -lexif -lz -ldl
}

android {

    contains(ANDROID_TARGET_ARCH, armeabi-v7a) {

        DEPS_PATH = $$DEPS_PATH/android_arm7
    }

    PRE_TARGETDEPS += $$LIBZWAY_PATH/libzway.a

    INCLUDEPATH += $$DEPS_PATH/include
    DEPENDPATH  += $$DEPS_PATH/include
    LIBS        += -L$$LIBZWAY_PATH -L$$DEPS_PATH/lib -lzway -lgnutls -lhogweed -lnettle -lgmp -lsqlite3 -lexif
}

macx:!ios {

    DEPS_PATH = $$DEPS_PATH/osx

    PRE_TARGETDEPS += $$LIBZWAY_PATH/libzway.a

    INCLUDEPATH += $$DEPS_PATH/include
    DEPENDPATH  += $$DEPS_PATH/include
    LIBS        += -L$$LIBZWAY_PATH -L$$DEPS_PATH/lib -lzway -lgnutls -lhogweed -lnettle -lgmp -lsqlite3 -lexif -liconv -lz
}

ios {

    # deps path

    INCLUDEPATH += $$DEPS_PATH/ios_i386/include
    DEPENDPATH  += $$DEPS_PATH/ios_i386/include
    LIBS        += -L$$DEPS_PATH/lib -lzway -lgnutls -lhogweed -lnettle -lgmp -lsqlite3 -lexif -liconv
}

win32 {

    contains(QT_ARCH, x86_64): {
        DEPS_PATH = $$LIBZWAY_ROOT/build/install/win_64
    } else {
        DEPS_PATH = $$LIBZWAY_ROOT/build/install/win_32
    }

    INCLUDEPATH += $$DEPS_PATH/include
    DEPENDPATH += $$DEPS_PATH/include
    LIBS += -L$$DEPS_PATH/lib -lzway -lgnutls -lhogweed -lnettle -lgmp -lsqlite3 -lexif -lws2_32 -lcrypt32
}
