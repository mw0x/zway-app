
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

    function info(message) {

        text.text += '<font color="white">' + new Date().toLocaleTimeString() + ": " + message + "<br>"
    }

    function warning(message) {

        text.text += '<font color="orange">' + new Date().toLocaleTimeString() + ": " + message + "<br>"
    }

    function error(message) {

        text.text += '<font color="red">' + new Date().toLocaleTimeString() + ": " + message + "<br>"
    }

    anchors.fill: parent
    color: "black"

    Flickable {
        id: flick
        anchors.fill: parent

        contentHeight: text.height
        flickableDirection: Flickable.VerticalFlick

        Text {
            id: text
            anchors {left: parent.left; right: parent.right}
            textFormat: Text.RichText
            color: "lime"
        }
    }
}

