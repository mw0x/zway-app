
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
import "controls" as Controls

Item {
    id: wrapper

    function show() {

        focus = true;

        actionMenu.opacity = 1;
    }

    function hide() {

        views.focus = true;

        actionMenu.opacity = 0;
    }

    property var actions

    signal actionClicked(string actionId)

    visible: actionMenu.opacity > 0

    MouseArea {
        anchors.fill: parent
        onPressed: hide()
    }

    Rectangle {
        id: actionMenu
        anchors {top: parent.top; right: parent.right; margins: 6 * dp}
        width: col.width + border.width * 2
        height: col.height + border.width * 2
        border.width: 1 * dp
        border.color: theme.ActionMenu.borderColor
        color: theme.ActionMenu.backgroundColor
        opacity: 0

        Behavior on opacity {
            NumberAnimation { duration: 350 }
        }

        Column {
            id: col
            anchors.centerIn: parent

            Repeater {
                model: actions
                onItemAdded: col.width = item.width

                Item {
                    width: row.width > col.width ? row.width + 24 * dp : col.width
                    height: row.height + 24 * dp
                    clip: true

                    Timer {
                        id: clickTimer
                        interval: 250
                        onTriggered: {

                            wrapper.hide();

                            wrapper.actionClicked(modelData.actionId)
                        }
                    }

                    Controls.SpreadEffect {
                        id: spread
                        anchors.fill: parent
                    }

                    Row {
                        id: row
                        anchors {left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 12 * dp}
                        spacing: 12 * dp

                        Image {
                            source: modelData.image
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: theme.ActionMenu.fontSize * sp
                            text: modelData.label
                        }
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        onClicked: clickTimer.start()
                        onPressed: spread.start(mouseX, parent.height / 2)
                        onReleased: spread.finish()
                        onCanceled: spread.finish()
                    }
                }
            }
        }
    }

    Keys.onBackPressed: hide()

    Keys.onEscapePressed: hide()
}

