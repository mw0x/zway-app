
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
import "views" as Views
import "controls" as Controls

Controls.SwipeArea {
    id: views

    property alias actionBarState: actionBar.state

    Component.onCompleted: {

        backend.loginSuccess.connect(function() {

            if (contactView.visible && actionBarState !== "search") {

                contactModel.updateItems();
            }
        });

        backend.contactRequest.connect(function() {

            if (contactView.visible && actionBarState !== "search") {

                contactModel.updateItems();
            }
        });

        backend.contactRequestAccepted.connect(function() {

            if (contactView.visible && actionBarState !== "search") {

                contactModel.updateItems();
            }
        });

        backend.contactRequestRejected.connect(function() {

            if (contactView.visible && actionBarState !== "search") {

                contactModel.updateItems();
            }
        });

        backend.contactStatusChanged.connect(function() {

            if (contactView.visible && actionBarState !== "search") {

                contactModel.updateItems();
            }
        });

        backend.messageIncoming.connect(function(message) {

            if (!(historyView.visible && historyView.contact && historyView.contact.id === message.src)) {

                if (backend.updateInbox(message.src, message.id)) {

                    if (contactView.visible && actionBarState !== "search") {

                        contactModel.updateItems();
                    }
                }
            }
        });

        backend.nativeCallback.connect(function(type, data) {

            if (type === 101) {

                historyView.show(data.src);
            }
        });
    }

    function init() {

        var label = backend.accountName();

        navigationDrawer.items = [
            {label: label, image: "/res/icons/" + dpiPrefix + "/logo1.png", bold: true},
            {label: "Chat", image: "/res/icons/" + dpiPrefix + "/ic_message_black.png"},
            {label: "Store", image: "/res/icons/" + dpiPrefix + "/ic_sd_storage_black.png"}
        ];

        contactView.show();
    }

    function goBack() {

        if (!viewSwitcher.currentView.goBack || !viewSwitcher.currentView.goBack()) {

            backend.sendToBack();
        }
        else {

            views.focus = true;
        }
    }

    function search(what) {

        if (viewSwitcher.currentView.search) {

            if (actionBar.state === "search") {

                Qt.inputMethod.commit();

                searchInput.text = searchInput.text || what || "";
            }
            else {

                searchInput.text = what || "";

                actionBar.state = "search";
            }

            viewSwitcher.currentView.search(searchInput.text.trim());
        }
    }

    anchors.fill: parent

    Item {
        anchors.fill: parent

        Views.Switcher {
            id: viewSwitcher
            anchors {top: actionBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom}

            Views.Contact {
                id: contactView
                width: parent.width
                height: parent.height
            }

            Views.Content {
                id: contentView
                width: parent.width
                height: parent.height
            }

            Views.History {
                id: historyView
                width: parent.width
                height: parent.height
            }

            Views.Settings {
                id: settingsView
                width: parent.width
                height: parent.height
            }
        }

        ActionBar {
            id: actionBar

            effect: Controls.SpreadEffect {
                anchors.fill: parent
                backColor: "#00000000"
                startValue: 0.25
                spreadRadius: height * 0.6
            }

            ActionButton {
                id: zwayButton
                anchors {left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 4 * dp}
                image: "/res/icons/" + dpiPrefix + "/logo1.png"
                onClicked: navigationDrawer.show()

                Controls.Badge {
                    anchors {right: parent.right; bottom: parent.bottom}
                    visible: !!text.length
                    text: ""
                }
            }

            ActionButton {
                id: backButton
                anchors {left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 4 * dp}
                image: "/res/icons/" + dpiPrefix + "/ic_arrow_back_white.png"
                visible: false
                onClicked: goBack()
            }

            ActionGroup {
                id: chatActionsGroup
                anchors {left: backButton.right; leftMargin: 12 * dp}
                spacing: 12 * dp

                ActionButton {
                    id: contactButton
                    image: "/res/icons/" + dpiPrefix + "/ic_action_person_white.png"
                    onClicked: contactView.show()

                    Controls.Badge {
                        anchors {right: parent.right; bottom: parent.bottom}
                        visible: !!text.length
                        text: ""
                    }
                }

                ActionButton {
                    image: "/res/icons/" + dpiPrefix + "/ic_action_group_white.png"
                    enabled: false
                }
            }

            Item {
                id: contactNameBox

                clip: true
                visible: false

                anchors {left: chatActionsGroup.right; right: actions2.left; top: parent.top; bottom: parent.bottom; leftMargin: 12 * dp; rightMargin: 12 * dp}

                Rectangle {

                    readonly property real desiredWith: contactName.width + 24 * dp

                    anchors {right: parent.right; verticalCenter: parent.verticalCenter}
                    width: desiredWith > parent.width ? parent.width : desiredWith
                    height: contactName.height + 12 * dp
                    color: theme.backgroundColor
                    radius: 6 * dp

                    Text {
                        id: contactName
                        anchors.centerIn: parent
                        text: historyView.contact ? historyView.contact.name : ""
                        font.pixelSize: 11 * sp
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {

                            // ...
                        }
                    }
                }
            }

            ActionGroup {
                id: storeActionsGroup
                anchors {left: backButton.right; leftMargin: 12 * dp}
                spacing: 12 * dp

                ActionButton {
                    id: fileSystemButton
                    image:  "/res/icons/" + dpiPrefix + (active ? "/ic_sd_storage_white_active.png" : "/ic_sd_storage_white.png")
                    onClicked: contentView.show(1)
                    active: contentView.activeModel === fileSystemModel
                }

                ActionButton {
                    id: localStoreButton
                    image: "/res/icons/" + dpiPrefix + (active ? "/ic_sd_storage_white_lock_active.png" : "/ic_sd_storage_white_lock.png")
                    onClicked: contentView.show(2)
                    active: contentView.activeModel === localStoreModel
                }

                ActionButton {
                    id: remoteStoreButton
                    image: "/res/icons/" + dpiPrefix + "/ic_cloud_white.png"
                    enabled: false
                }
            }

            TextInput {
                id: searchInput
                anchors {left: backButton.right; right: actions2.left;  verticalCenter: parent.verticalCenter; margins: 6 * dp}
                color: "white"
                font.pixelSize: 14 * sp
                visible: false

                Keys.onReturnPressed: search()
            }

            ActionGroup {
                id: actions2
                anchors {right: menuButton.left}
                spacing: 12 * dp
                buttonWidth: 24 * dp

                ActionButton {
                    id: addButton
                    image: "/res/icons/" + dpiPrefix + "/ic_add_white.png"
                    visible: false
                    onClicked: {

                        switch (viewSwitcher.currentView) {

                            case contactView:

                                contactView.addContact();

                                break;

                            case contentView:

                                contentView.addItem();

                                break;
                        }
                    }
                }

                ActionButton {
                    id: deleteButton
                    image: "/res/icons/" + dpiPrefix + "/ic_delete_white.png"
                    visible: false
                    onClicked: {

                        switch (views.state) {

                            case "history":

                                historyView.clear();

                                break;
                        }
                    }
                }

                ActionButton {
                    id: searchButton
                    image: "/res/icons/" + dpiPrefix + "/ic_search_white.png"
                    visible: false
                    onClicked: search()
                }
            }

            ActionButton {
                id: menuButton
                anchors {right: parent.right; verticalCenter: parent.verticalCenter}
                image: "/res/icons/" + dpiPrefix + "/ic_more_vert_white.png"
                onClicked: actionMenu.show()
            }

            states: [
                State {
                    name: "search"
                    PropertyChanges { target: zwayButton; visible: false }
                    PropertyChanges { target: backButton; visible: true }
                    PropertyChanges { target: chatActionsGroup; visible: false }
                    PropertyChanges { target: storeActionsGroup; visible: false }
                    PropertyChanges { target: addButton; visible: false }
                    PropertyChanges { target: deleteButton; visible: false }
                    PropertyChanges { target: searchButton; visible: true }
                    PropertyChanges { target: searchInput; visible: true; focus: true }
                },
                State {
                    name: "back"
                    PropertyChanges { target: zwayButton; visible: false }
                    PropertyChanges { target: backButton; visible: true }
                    PropertyChanges { target: chatActionsGroup; visible: false }
                    PropertyChanges { target: storeActionsGroup; visible: false }
                    PropertyChanges { target: actions2; visible: false }
                },
                State {
                    name: "content_callback"
                    PropertyChanges { target: zwayButton; visible: false }
                    PropertyChanges { target: backButton; visible: true }
                    PropertyChanges { target: actions2; visible: false }
                }
            ]
        }

        ActionMenu {
            id: actionMenu
            anchors.fill: parent

            onActionClicked: {

                switch (actionId) {

                    case "settings":

                        settingsView.show();

                        break;

                    case "help":

                        /*
                        backend.checkPhoneContacts(function(err, res) {

                            contactModel.updateItems();
                        });
                        */

                        break;

                    case "logout":

                        busyBox.show("", function() {

                            backend.logout();
                        });

                        break;
                }
            }

            actions: [
                {actionId: "settings", label: "Settings", image: "/res/icons/" + dpiPrefix + "/ic_settings_black.png"},
                {actionId: "help",     label: "Help",     image: "/res/icons/" + dpiPrefix + "/ic_help_black.png"},
                {actionId: "logout",   label: "Logout",   image: "/res/icons/" + dpiPrefix + "/ic_exit_to_app_black.png"}
            ]
        }

        Controls.NavigationDrawer {
            id: navigationDrawer

            property var items

            function onItemClicked(index) {

                if (index === 0) {

                    return;
                }

                if (index === 1) contactView.show();
                else
                if (index === 2) contentView.show();

                navigationDrawer.hide();
            }

            swipeArea: views
            interactive: !backButton.visible
            contentWidth: 288 * dp
            offset: 20 * dp

            Rectangle {
                id: navigationDrawerContent
                anchors.fill: parent
                color: theme.NavigationDrawer.backgroundColor
                clip: true

                ListView {
                    anchors.fill: parent
                    model: navigationDrawer.items
                    boundsBehavior: ListView.StopAtBounds

                    delegate: Column {
                        anchors {left: parent.left; right: parent.right}

                        Timer {
                            id: clickTimer
                            interval: 250
                            onTriggered: navigationDrawer.onItemClicked(index)
                        }

                        Rectangle {
                            id: wrap
                            anchors {left: parent.left; right: parent.right}
                            color: modelData.bold ? "white" : theme.NavigationDrawer.itemColor
                            height: row.height + 8 * dp
                            clip: true

                            Controls.SpreadEffect {
                                id: spread
                                visible: index > 0
                                anchors.fill: parent
                            }

                            Row {
                                id: row
                                anchors {verticalCenter: parent.verticalCenter; left: parent.left; margins: 4 * dp}
                                spacing: 12 * dp

                                Item {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 48 * dp
                                    height: 48 * dp

                                    Image {
                                        id: img
                                        anchors.centerIn: parent
                                        source: modelData.image;
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    font.pixelSize: theme.NavigationDrawer.fontSize * sp
                                    text: modelData.label
                                    font.weight: modelData.bold ? Font.Bold : Font.Normal
                                }
                            }

                            Controls.Badge {
                                anchors {right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 * dp}
                                visible: !!text.length
                                text: {
                                    if (index === 1) {
                                        ""
                                    }
                                    else
                                    if (index === 2) {
                                        ""
                                    }
                                    else {
                                        ""
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: clickTimer.start()
                                onPressed: spread.start(mouseX, wrap.height / 2)
                                onReleased: spread.finish()
                                onCanceled: spread.finish()
                            }
                        }

                        Rectangle {
                            anchors {left: parent.left; right: parent.right}
                            height: 1 * dp
                            color: theme.NavigationDrawer.separatorColor
                        }
                    }
                }
            }

            /*
            Image {
                anchors {top: parent.top; left: navigationDrawerContent.right; bottom: parent.bottom}
                visible: navigationDrawer.contentX > -navigationDrawer.contentWidth
                source: "/res/gradients/" + dpiPrefix + "/drawer_shadow_v.png"
                fillMode: Image.TileVertically
            }
            */
        }

        ActionPicker {
            id: actionPicker
            anchors.fill: parent
        }
    }

    Keys.onBackPressed: goBack()

    Keys.onEscapePressed: goBack()

    states: [
        State {
            name: "contact"
            PropertyChanges { target: chatActionsGroup; visible: true }
            PropertyChanges { target: storeActionsGroup; visible: false }
            PropertyChanges { target: addButton; visible: true }
            PropertyChanges { target: searchButton; visible: true }
            PropertyChanges { target: contactView; visible: true; focus: true }
        },
        State {
            name: "history"
            PropertyChanges { target: chatActionsGroup; visible: true }
            PropertyChanges { target: contactNameBox; visible: true }
            PropertyChanges { target: storeActionsGroup; visible: false }
            PropertyChanges { target: deleteButton; visible: true }
            PropertyChanges { target: historyView; visible: true; focus: true }
        },
        State {
            name: "content"
            PropertyChanges { target: chatActionsGroup; visible: false }
            PropertyChanges { target: storeActionsGroup; visible: true }
            PropertyChanges { target: addButton; visible: true }
            PropertyChanges { target: contentView; visible: true; focus: true }
            PropertyChanges { target: actionBar; state: contentView.callback ? "content_callback" : "" }
        },
        State {
            name: "settings"
            PropertyChanges { target: settingsView; visible: true }
            PropertyChanges { target: actionBar; state: "back" }
        }
    ]
}

