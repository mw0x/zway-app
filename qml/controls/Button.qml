
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
    id: button
    width: label.width + 42 * dp > theme.Button.minWidth ? label.width + 42 * dp : theme.Button.minWidth
    height: label.height * 1.2 + 24 * dp
    color: "#C8C8C8"
    clip: true

    property alias text: label.text

    signal clicked

    Timer {
        id: timer
        interval: 250
        onTriggered: button.clicked()
    }

    SpreadEffect {
        id: spread
        anchors.fill: parent
    }

    Text {
        id: label
        anchors.centerIn: parent
        font.pixelSize: theme.Button.fontSize * sp
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: timer.start()
        onPressed: spread.start(mouseX, button.height / 2)
        onReleased: spread.finish()
        onCanceled: spread.finish()
    }
}
