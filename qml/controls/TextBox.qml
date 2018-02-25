
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

FocusScope {
    id: scope

    property alias edit: textEdit

    property alias text: textEdit.text

    property int minHeightLines: 1
    property int maxHeightLines: 6

    readonly property real lineOffset: 2 * sp
    readonly property real lineHeight: textEdit.font.pixelSize + lineOffset

    readonly property real minHeight: minHeightLines * lineHeight
    readonly property real maxHeight: maxHeightLines * lineHeight

    clip: true
    height: textEdit.height > maxHeight ? maxHeight : ( textEdit.height < minHeight ? minHeight : textEdit.height)

    function plainText() { return textEdit.getText(0, textEdit.length).replace(/\0/, ''); }

    Flickable {
        id: flickable

        width: parent.width
        height: parent.height

        contentWidth: parent.width
        contentHeight: textEdit.height

        flickableDirection: Flickable.VerticalFlick

        TextEdit {
            id: textEdit

            property real cursorY: 0

            focus: true
            width: parent.width
            wrapMode: Text.Wrap
            Keys.forwardTo: scope

            onCursorYChanged: {

                if (cursorY < flickable.contentY) {

                    flickable.contentY = cursorY;
                }
                else
                if (cursorY >= flickable.contentY + flickable.height) {

                    flickable.contentY += cursorY - (flickable.contentY + flickable.height) + cursorRectangle.height;
                }
            }

            onCursorRectangleChanged: cursorY = cursorRectangle.y
        }
    }
}
