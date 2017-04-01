
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
import QtQuick.Window 2.2
import "screens" as Screens

Window {
    id: wnd

    property int virtualKeyboardDelta : 0

    visible: true
    width: 400
    height: 640
    minimumWidth: 400

    color: theme.backgroundColor

    Item {
        anchors {top: statusBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom}

        Views {
            id: views
            visible: false
        }

        Screens.Console {
            id: consoleScreen
            visible: false
        }

        Screens.CreateAccount {
            id: createAccountScreen
        }

        Screens.Login {
            id: loginScreen
        }

        Screens.Image {
            id: imageScreen
        }

        Dialog {
            id: dialog
        }

        Status {
            id: status
        }

        BusyBox {
            id: busyBox
        }
    }

    Rectangle {
        id: statusBar
        color: theme.ActionBar.color
        anchors {left: parent.left; right: parent.right}
        height: Qt.application.state === Qt.ApplicationActive ? statusBarHeight : 0
    }


    onClosing: {

        if (!backend.handleClose()) {

            close.accepted = false;

            busyBox.show("Logging out", function() {

                backend.logout();

            });
        }
    }


    Component.onCompleted: {

        var nConFail = 0;


        backend.handleLog.connect(function(type, log) {

            if (type === 0) {

                consoleScreen.info(log.message);
            }
            else
            if (type === 1) {

                consoleScreen.error(log.message);
            }
            else
            if (type === 3) {

                status.show('<font color="white"><b>' + log.message);
            }
        });


        backend.connectionSuccess.connect(function() {

            nConFail = 0;
        });


        backend.connectionFailure.connect(function(args) {

            if (!(nConFail % 4)) {

                status.show('<font color="white"><b>Failed to connect!');
            }

            nConFail++;
        });


        backend.connectionInterrupted.connect(function() {

            status.show('<font color="white"><b>Connection interrupted!');
        });


        backend.disconnected.connect(function() {

            status.show('<font color="white"><b>Disconnect!');
        });


        backend.nativeCallback.connect(function(type, data) {

            if (type === 3000 ||
                type === 3001) {

                virtualKeyboardDelta = data.delta;
            }
        });

        backend.ready.connect(function(err, storeFile, storePass) {

            if (!err) {

                if (storeFile && storePass) {

                    backend.unlockStore(storeFile, storePass, function(err) {

                        if (!err) {

                            views.init();

                            views.visible = true;

                            views.focus = true;

                            backend.login();
                        }
                        else {

                            status.show('<font color="white"><b>' + err.message);
                        }
                    });
                }
                else
                if (storeFile) {

                    loginScreen.show(storeFile);
                }
                else {

                    createAccountScreen.show();
                }
            }
            else {

                dialog.info("", "Permission denied", function() {

                    Qt.quit();
                });
            }
        });

        backend.init();
    }
}
