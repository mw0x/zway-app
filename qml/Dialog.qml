
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
import QtQuick.Layouts 1.2
import "controls" as Controls

Item {
    id: dialog

    property var prevFocusItem

    property var callback

    property bool accepted

    property alias inputText: input.text

    function info(title, message, callback) {

        messageBox(title, message, "/res/icons/" + dpiPrefix + "/icon_info.png", callback);

    }

    function confirm(title, message, callback) {

        messageBox(title, message, "/res/icons/" + dpiPrefix + "/icon_question.png", callback);
    }

    function messageBox(title, message, icon, callback) {

        dialog.prevFocusItem = wnd.activeFocusItem ? wnd.activeFocusItem.focusScope || wnd.activeFocusItem : null;

        dialog.callback = callback;

        dialog.accepted = false;

        image.source = icon;

        titleText.text = title;

        messageText.text = message;

        // focus scope !!??

        input.visible = false;

        opacity = 1;
    }

    function prompt(title, message, callback) {

        dialog.prevFocusItem = wnd.activeFocusItem ? wnd.activeFocusItem.focusScope || wnd.activeFocusItem : null;

        dialog.callback = callback;

        dialog.accepted = false;

        image.source = "";

        titleText.text = title;

        messageText.text = message;

        input.text = "";

        // focus scope !!??

        input.visible = true;

        input.focus = true;

        opacity = 1;
    }

    function accept() {

        if (!input.visible || input.text.length) {

            accepted = true;

            hide();

            if (callback) {

                callback();
            }
        }
    }

    function dismiss() {

        hide();

        if (callback) {

            callback();
        }
    }

    function hide() {

        focus = false;

        if (prevFocusItem) {

            if (prevFocusItem.isHistoryInput !== true) {

                prevFocusItem.focus = true;
            }
            else {

                prevFocusItem.parent.focus = true;
            }
        }

        opacity = 0;

        Qt.inputMethod.hide();
    }

    anchors.fill: parent

    visible: opacity > 0
    opacity: 0

    Behavior on opacity {
        NumberAnimation { duration: 350 }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.5
    }

    Item {
        anchors {fill: parent; bottomMargin: wnd.virtualKeyboardDelta}

        Rectangle {
            anchors.centerIn: parent
            width: col.width + 24 * dp
            height: col.height + 24 * dp
            color: theme.ActionPicker.backgroundColor
            border.color: theme.ActionPicker.borderColor
            radius: theme.ActionPicker.borderRadius * dp

            ColumnLayout {
                id: col
                anchors.centerIn: parent
                spacing: 12 * dp

                RowLayout {
                    spacing: 12 * dp

                    Image {
                        id: image
                        Layout.alignment: Qt.AlignTop
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignTop

                        Text {
                            id: titleText
                            visible: !!text.length
                            Layout.maximumWidth: 200 * dp
                            wrapMode: Text.Wrap
                            font.pixelSize: 22 * sp
                            font.weight: Font.Bold
                        }

                        Text {
                            id: messageText
                            visible: !!text.length
                            Layout.maximumWidth: 200 * dp
                            wrapMode: Text.Wrap
                            font.pixelSize: 16 * sp
                        }

                        Controls.LineEdit {
                            id: input
                            width: 250 * dp
                            Keys.onReturnPressed: accept()
                        }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 6 * dp

                    Controls.Button {
                        text: "OK"
                        onClicked: accept()
                    }

                    Controls.Button {
                        text: "Cancel"
                        onClicked: dismiss()
                    }
                }
            }
        }
    }
}

