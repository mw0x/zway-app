
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
import "../controls" as Controls

Rectangle {

    function show() {

        opacity = 1;
    }

    function hide() {

        opacity = 0;
    }

    function createAccount() {

        function go() {

            Qt.inputMethod.hide();

            var account = {
                name        : name.text.trim(),
                password    : password1.text.trim(),
                phone       : phoneNumber,
                findByName  : findByName.checked,
                findByPhone : findByPhone.checked
            };

            busyBox.show("Creating account", function() {

                backend.createAccount(account, function(err, data) {

                    busyBox.hide();

                    if (!err) {

                        status.show('<font color="white"><b>Your account has been created!');

                        hide();

                        //loginScreen.show(data.storeFilename);

                        backend.unlockStore(data.storeFilename, data.storePassword, function(err) {

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
                    else {

                        status.show('<font color="white"><b>' + err.message);
                    }
                });
            });
        }

        Qt.inputMethod.commit();

        if (!name.text.length) {

            status.show("Please enter username!");

            return;
        }

        if (password1.length === 0) {

            status.show("Please enter password!");

            return;
        }

        if (password1.length < 8) {

            status.show("Password must be at least 8 digits!");

            return;
        }

        if (password2.text !== password1.text) {

            status.show("Passwords do not match!");

            return;
        }

        /*
        if (!backend.connected()) {

            status.show('<font color="white"><b>You are not connected!');

            return;
        }
        */

        var phoneNumber;

        if (findByPhone.checked) {

            phoneNumber = backend.clientPhoneNumber();

            if (!phoneNumber) {

                dialog.prompt("", "Your phone number could not be determined!<br>Please enter it manually:", function() {

                    if (dialog.accepted) {

                        phoneNumber = backend.formatPhoneNumber(dialog.inputText);

                        if (!phoneNumber) {

                            status.show("Something was wrong with your input!");
                        }
                        else {

                            go();
                        }
                    }
                });
            }
            else {

                go();
            }
        }
        else {

            go();
        }
    }

    anchors.fill: parent

    visible: opacity > 0
    opacity: 0

    color: "#D6D6D6"

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
                anchors.centerIn: parent
                width: col.width + 24 * dp
                height: col.height + 24 * dp
              //border.color: "#707070"
              //radius: 6 * dp
                color: "#00000000"

                Column {
                    id: col
                    anchors.centerIn: parent
                    width: 288 * dp
                    spacing: 16 * dp

                    Text {
                        anchors {left: parent.left; right: parent.right}
                        font.pixelSize: 28 * sp
                        font.weight: Font.Bold
                        text: "Create account"
                    }

                    Text {
                        anchors {left: parent.left; right: parent.right}
                        font.pixelSize: 18 * sp
                        text: "Username:"

                    }

                    Controls.LineEdit {
                        id: name
                        anchors {left: parent.left; right: parent.right}
                        text: "User1"
                        KeyNavigation.tab: password1
                    }

                    Text {
                        anchors {left: parent.left; right: parent.right}
                        font.pixelSize: 18 * sp
                        text: "Store password:"
                    }

                    Controls.LineEdit {
                        id: password1
                        anchors {left: parent.left; right: parent.right}
                        password: true
                        text: ""
                        KeyNavigation.tab: password2
                    }

                    Text {
                        anchors {left: parent.left; right: parent.right}
                        font.pixelSize: 18 * sp
                        text: "Store password again:"
                    }

                    Controls.LineEdit {
                        id: password2
                        anchors {left: parent.left; right: parent.right}
                        password: true
                        text: ""
                        KeyNavigation.tab: name
                    }

                    Controls.CheckBox {
                        id: findByName
                        anchors {left: parent.left; right: parent.right}
                        text: "Make me findable by user name"
                    }

                    Controls.CheckBox {
                        id: findByPhone
                        anchors {left: parent.left; right: parent.right}
                        text: "Make me findable by phone number"
                        visible: Qt.platform.os === "android" || Qt.platform.os === "ios"
                    }

                    Controls.Button {
                        anchors {right: parent.right}
                        text: "Create account"
                        onClicked: createAccount()
                    }
                }
            }
        }
    }

    Keys.onReturnPressed: createAccount()
}
