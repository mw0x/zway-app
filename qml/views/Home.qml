
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
import "../controls" as Controls

Item {

    function show() {

        views.state = "home";
    }

    function onItemClicked(index) {

        //var item = homeModel.get(index);
    }

    ListView {
        id: listView
        anchors.fill: parent

        property int pressedIndex: -1;

        add: Transition {
            NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 250; }
        }

        clip: true

        //model: homeModel

        delegate: Column {
            anchors {left: parent.left; right: parent.right}

            Rectangle {
                id: wrap
                width: parent.width;
                height: image.height + 24 * dp
                color: theme.HomeView.itemColor
                clip: true

                Timer {
                    id: timer
                    interval: 250
                    onTriggered: homeView.onItemClicked(index)
                }

                Controls.SpreadEffect {
                    id: spread
                    anchors.fill: parent
                }

                Image {
                    id: image
                    anchors {left: parent.left; verticalCenter: parent.verticalCenter; margins: 16 * dp}
                    source: {

                        if (type === 2000 || type === 2010) {

                            "/res/icons/" + dpiPrefix + "/ic_action_add_person_black.png"
                        }
                    }
                }

                Text {
                    anchors {left: image.right;
                    verticalCenter: parent.verticalCenter; margins: 12 * dp}
                    font.pixelSize: theme.HomeView.fontSize * sp
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: timer.start()
                    onPressed: spread.start(mouseX, wrap.height / 2)
                    onReleased: spread.finish()
                    onCanceled: spread.finish()
                }
            }

            Rectangle {
                width: parent.width;
                height: 2 * dp
                color: theme.HomeView.separatorColor
            }
        }
    }
}
