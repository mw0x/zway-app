
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

    property color backColor: "#C0C0C0"

    property color spreadColor: "#B0B0B0"

    property real spreadRadius: width

    property real startValue: 0

    function start(originX, originY) {

        state = "";

        spread.x = originX - spreadRadius;
        spread.y = originY - spreadRadius;

        state = "started";
    }

    function finish() {

        state = "finished";
    }

    Rectangle {
        id: back
        anchors.fill: parent
        opacity: 0
        color: backColor
    }

    Rectangle {
        id: spread
        scale: startValue
        opacity: 0
        color: spreadColor
        width: spreadRadius * 2
        height: spreadRadius * 2
        radius: spreadRadius
    }

    states: [
        State {
            name: "started"
            PropertyChanges {
                target: back
                opacity: 1
            }
            PropertyChanges {
                target: spread
                scale: 1
                opacity: 1
            }
        },
        State {
            name: "finished"
            PropertyChanges {
                target: back
                opacity: 0
            }
            PropertyChanges {
                target: spread
                scale: 1
                opacity: 0
            }
        }
    ]

    transitions: [
        Transition {
            to: "started"

            NumberAnimation {
                target: spread
                property: "scale"
                duration: 2000
            }

            NumberAnimation {
                target: spread
                property: "opacity"
                duration: 250
            }
        },
        Transition {
            to: "finished"
            NumberAnimation {
                target: back
                property: "opacity"
                duration: 250
            }
            NumberAnimation {
                target: spread
                property: "scale"
                duration: 500
            }
            NumberAnimation {
                target: spread
                property: "opacity"
                duration: 500
            }
        }
    ]

}

