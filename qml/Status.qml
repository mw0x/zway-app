
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

import QtQuick 2.7

Rectangle {
    id: status

    property int minHeight: 56 * dp

    function show(text, keepVisible) {

        message.text = text || "";

        y = 0;

        opacity = 1;

        if (!keepVisible) {

            timer.start();
        }
    }

    function hide() {

        y = - (height / 2);

        opacity = 0;
    }

    anchors {left: parent.left; right: parent.right}
    height: childrenRect.height + 24 * dp > minHeight ? childrenRect.height + 24 * dp : minHeight
    color: "#DC3847"

    y: - (height / 2)

    visible: opacity > 0
    opacity: 0

    Timer {
        id: timer
        interval: 1500
        onTriggered: hide()
    }

    Behavior on opacity {
        NumberAnimation { duration: 350 }
    }

    Behavior on y {
        NumberAnimation { duration: 350 }
    }

    Image {
        id: image
        anchors {top: parent.top; left: parent.left; margins: 12 * dp}
    }

    Text {
        id: message
        anchors {left: image.right; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 * dp}
        wrapMode: Text.Wrap
        font.pixelSize: theme.Status.fontSize * sp

        text: "test"
    }
}

