
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
import "../utils.js" as Utils

Rectangle {

    function show(url) {

        console.debug(url)

        ImageService.loadImage(url, null, function(err, url, data) {

            if (!err) {

                img.source = url;
            }
            else {

                console.debug("Failed to load image", url)
            }
        });

        opacity = 1;
    }

    function hide() {

        opacity = 0;
    }

    anchors.fill: parent

    visible: opacity > 0
    opacity: 0

    color: "black"

    Behavior on opacity {
        NumberAnimation { duration: 350 }
    }

    Image {
        id: img
        anchors.centerIn: parent
    }

    Image {
        source: "/res/icons/" + dpiPrefix + "/ic_cancel_white.png"
        anchors {top: parent.top; right: parent.right; margins: 12 * dp}
        MouseArea {
            anchors.fill: parent
            onClicked: hide()
        }
    }
}
