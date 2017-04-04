
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

Rectangle {

    property var storeFiles;

    function show(storeFile) {

        storeFiles = storeFile.split(';');

        opacity = 1;

        password.focus = true;
    }

    function hide() {

        opacity = 0;
    }

    function login(storeFile) {

        Qt.inputMethod.commit();

        if (password.text.length === 0) {

            status.show("Please enter password!");

            return;
        }

        Qt.inputMethod.hide();

        backend.unlockStore(storeFile, password.text.trim(), function(err) {

            if (!err) {

                views.init();

                views.visible = true;

                views.focus = true;

                hide();

                backend.login(function(err) {

                    if (err) {

                        status.show('<font color="white"><b>' + err.message);
                    }
                });
            }
            else {

                status.show('<font color="white"><b>' + err.message);
            }
        });
    }

    anchors.fill: parent

    visible: opacity > 0
    opacity: 0

    color: "#D6D6D6"

    /*
    Timer {
        id: timer
        interval: 350
        onTriggered: busyBox.hide()
    }
    */

    Behavior on opacity {
        NumberAnimation { duration: 350 }
    }

    Flickable {
        id: flick
        anchors {fill: parent; bottomMargin: wnd.virtualKeyboardDelta}
        contentWidth: wrap.width
        contentHeight: wrap.height
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Item {
            id: wrap
            width: flick.width
            height: content.height + 24 * dp

            Rectangle {
                id: content
                anchors {top: parent.top; horizontalCenter: parent.horizontalCenter; margins: 48 * dp}
                width: col.width + 24 * dp
                height: col.height + 24 * dp
              //border.color: "#707070"
              //radius: 6 * dp
                color: "#00000000"

                Column {
                    id: col
                    anchors.centerIn: parent
                    width: 288 * dp
                    spacing: 20 * dp

                    Text {
                        anchors {left: parent.left; right: parent.right}
                        font.pixelSize: 28 * sp
                        font.weight: Font.Bold
                        text: "Unlock store"
                    }

                    Text {
                        anchors {left: parent.left; right: parent.right}
                        font.pixelSize: 18 * sp
                        text: "Password:"
                    }

                    Controls.LineEdit {
                        id: password
                        anchors {left: parent.left; right: parent.right}
                        password: true
                        text: ""
                    }

                    Controls.Button {
                        anchors {right: parent.right}
                        text: "Login"
                        onClicked: login(storeFiles[0])
                    }
                }
            }
        }
    }

    // for testing purposes

    ListView {
        id: stores
        anchors {left: parent.left; right: parent.right; bottom: parent.bottom; margins: 24 * dp}
        height: contentHeight
        visible: (!!storeFiles && storeFiles.length > 1)
        model: (!!storeFiles && storeFiles.length > 1) ? storeFiles : null
        spacing: 8 * dp
        delegate: Rectangle {

            border.color: "gray"

            color: "#00000000"

            width: stores.width

            height: 24 * dp

            Text {
                anchors {verticalCenter: parent.verticalCenter; horizontalCenter: parent.horizontalCenter}
                font.pixelSize: 13 * sp
                text: "Store " + (index + 1)
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {

                var index = stores.indexAt(mouse.x, mouse.y);

                if (index !== -1) {

                    login(storeFiles[index]);
                }
            }
        }
    }

    Keys.onReturnPressed: login(storeFiles[0])
}
