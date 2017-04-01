
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

import QtQuick 2.7

FocusScope {
    id: scope

    property alias color: wrap.color
    property alias border: wrap.border
    property alias radius: wrap.radius

    property alias text: edit.text
    property alias length: edit.length

    property alias textEdit: edit

    property int padding: 6

    function plainText() {

        return edit.getText(0, edit.length);
    }

    Rectangle {
        id: wrap
        anchors.fill: parent

        Flickable {
            id: flick
            anchors {fill: parent; margins: padding}
            contentWidth: edit.paintedWidth
            contentHeight: edit.paintedHeight
            flickableDirection: Flickable.VerticalFlick
            clip: true

            onHeightChanged: {

                if (height < edit.cursorRectangle.y + edit.cursorRectangle.height) {

                    contentY = edit.cursorRectangle.y + edit.cursorRectangle.height - height;
                }
            }

            onContentHeightChanged: {

                if (contentHeight > height) {

                    contentY = contentHeight - height;
                }
            }

            TextEdit {
                id: edit
                focus: true
                width: flick.width
                height: flick.height > paintedHeight ? flick.height : paintedHeight

                Keys.forwardTo: scope
            }
        }
    }
}
