
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

Item {
    id: busyBox

    property var callback

    function show(text, callback) {

        statusText.text = text || "Please wait";

        busyBox.callback = callback;

        if (callback) {

            timer.start();
        }

        opacity = 1;
    }

    function hide() {

        opacity = 0;
    }

    anchors.fill: parent

    opacity: 0
    visible: opacity > 0

    Timer {
        id: timer
        interval: 350
        onTriggered: {

            if (callback) {

                callback();

                callback = null;
            }
        }
    }

    Behavior on opacity {
        NumberAnimation { duration: 350 }
    }

    onOpacityChanged: {

        if (opacity === 1 && callback) {

            callback();

            callback = null;
        }
    }

    Item {
        id: wrapper
        anchors {fill: parent; bottomMargin: wnd.virtualKeyboardDelta}

        Rectangle {
            anchors.fill: parent
            opacity: 0.5
            color: "#000000"

            MouseArea {
                anchors.fill: parent
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: row.width + 48 * dp
            height: row.height + 48 * dp
            color: "#d6d6d6"
            border.color: "#707070"
            radius: 6 * dp

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 12 * dp

                AnimatedImage {
                    id: spinner
                    source: "/res/spinners/" + dpiPrefix + "/spinner2.gif"
                }

                Text {
                    id: statusText
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 14 * sp
                }
            }
        }
    }
}
