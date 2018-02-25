
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

Item {

    default property var addContactActions: [
        {
            actionId : "CREATE_ADD_CODE",
            image    : "/res/icons/" + dpiPrefix + "/ic_add_black.png",
            label    : "Create add code"
        },
        {
            actionId : "CREATE_CONTACT_FROM_ADD_CODE",
            image    : "/res/icons/" + dpiPrefix + "/ic_add_black.png",
            label    : "Create contact from add code"
        },
        {
            actionId : "FIND_CONTACT",
            image    : "/res/icons/" + dpiPrefix + "/ic_search_black.png",
            label    : "Find contact"
        }
    ];

    function addContact() {

        actionPicker.show(addContactActions, function(actionId) {

            switch (actionId) {

                case "CREATE_ADD_CODE":

                    busyBox.show("", function() {

                        backend.createAddCode(function(err, res) {

                            busyBox.hide();

                            if (!err) {

                                dialog.info("", "<h1>" + res.addCode + "</h1>");
                            }
                            else {

                                status.show(err.message);
                            }
                        });
                    });

                    break;

                case "CREATE_CONTACT_FROM_ADD_CODE":

                    dialog.prompt("", "Add code:", function() {

                        busyBox.show("", function() {

                            backend.addContact(dialog.inputText.trim().toUpperCase(), "", "", function(err, res) {

                                busyBox.hide();

                                if (!err) {

                                    contactModel.updateItems();
                                }
                                else {

                                    status.show(err.message);
                                }
                            });
                        });
                    });

                    break;

                case "FIND_CONTACT":

                    views.search();

                    break;
            }
        });
    }

    function show() {

        contactModel.updateItems("", "", function() {

            views.state = "contact";
        });
    }

    function goBack() {

        if (views.actionBarState === "search") {

            views.actionBarState = "";

            contactModel.updateItems();

            return true;
        }
    }

    function search(what) {

        if (what) {

            if (backend.connected()) {

                //if (!backend.requestPending(2050)) {

                    busyBox.show("Searching", function() {

                        contactModel.updateItems("", what, function(r) {

                            busyBox.hide();
                        });
                    });
                //}
            }
            else {

                status.show('<font color="white"><b>You are not connected!');
            }
        }
        else {

            contactModel.clearItems();
        }
    }

    function onItemClicked(index) {

        var item = contactModel.get(index);

        if (item.type === 1) {

            dialog.confirm("Cancel", "Do you want to cancel the request?", function() {

                if (dialog.accepted) {

                    busyBox.show("Canceling request", function() {

                        backend.cancelRequest(item.id, function() {

                            busyBox.hide();

                            contactModel.updateItems();
                        });
                    });
                }
            });
        }
        else
        if (item.type === 2) {

            var actions = [
                {
                    actionId  : "ACCEPT_REQUEST",
                    requestId : item.id,
                    image     : "/res/icons/misc/drawable-" + dpiPrefix + "/ic_check_grey.png",
                    label     : "Accept"
                },
                {
                    actionId  : "REJECT_REQUEST",
                    requestId : item.id,
                    image     : "/res/icons/misc/drawable-" + dpiPrefix + "/ic_cancel_grey.png",
                    label     : "Reject"
                }
            ];

            actionPicker.show(actions, function(actionId, action) {

                switch (actionId) {

                    case "ACCEPT_REQUEST":

                        if (!backend.connected()) {

                            status.show('<font color="white"><b>You are not connected!');

                            break;
                        }

                        busyBox.show("Accepting contact", function() {

                            backend.acceptContact(action.requestId, function(err) {

                                busyBox.hide();

                                contactModel.updateItems();
                            });
                        });

                        break;

                    case "REJECT_REQUEST":

                        if (!backend.connected()) {

                            status.show('<font color="white"><b>You are not connected!');

                            break;
                        }

                        busyBox.show("Rejecting contact", function() {

                            backend.rejectContact(action.requestId, function(err) {

                                busyBox.hide();

                                contactModel.updateItems();
                            });
                        });

                        break;
                }
            });
        }
        else
        if (item.type === 3 || item.type === 4) {

            backend.deleteRequest(item.id, function() {

                contactModel.updateItems();
            });
        }
        else {

            if (item.id) {

                historyView.show(item.id);
            }
            else {

                var actions = [
                    {
                        actionId     : "ADD_CONTACT",
                        image        : "/res/icons/" + dpiPrefix + "/ic_action_add_person_black.png",
                        label        : "Send request to <b>" + item.name + "</b>",
                        contactName  : item.name,
                        contactPhone : item.phone
                    }
                ];

                actionPicker.show(actions, function(actionId, action) {

                    switch (actionId) {

                        case "ADD_CONTACT":

                            busyBox.show("Sending request", function() {

                                backend.addContact("", action.contactName, action.contactPhone, function(err, res) {

                                    busyBox.hide();

                                    if (!err) {

                                    }
                                    else {

                                        status.show(err.message);
                                    }
                                });
                            });

                            break;
                    }
                });
            }
        }
    }

    ListView {
        id: listView

        anchors.fill: parent

        clip: true

        interactive: !scrollBar.scrolling

        model: contactModel

        section.property: "contactGroup"

        section.delegate: Rectangle {
            anchors {left: parent.left; right: parent.right}
            height: 32 * dp
            Text {
                anchors {left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 12 * dp}
                text: {"request": "Contact requests", "contact": "Contacts"}[section]
                font.pixelSize: 13 * sp
            }
        }

        section.criteria: ViewSection.FullString

        delegate: Column {
            anchors {left: parent.left; right: parent.right}

            Rectangle {
                id: wrap
                width: parent.width;
                height: image.height + 32 * dp
                color: theme.ContactsView.itemColor
                clip: true

                Timer {
                    id: timer
                    interval: 250
                    onTriggered: contactView.onItemClicked(index)
                }

                Controls.SpreadEffect {
                    id: spread
                    anchors.fill: parent
                }

                Rectangle {
                    id: image
                    anchors {left: parent.left; verticalCenter: parent.verticalCenter; margins: 12 * dp}
                    width: 44 * dp
                    height: 44 * dp
                    radius: 22 * dp
                    color: contactColor || "#5d6d7e"

                    Text {
                        anchors.centerIn: parent
                        text: contactName.substr(0, 1)
                        font.pixelSize: 16 * sp
                        color: "white"
                    }

                    Rectangle {
                       id: numMessages
                       anchors {right: parent.right; bottom: parent.bottom; rightMargin: -6 * dp; bottomMargin: -6 * dp}
                       visible: contactInbox > 0
                       color: "red"
                       width: 24 * dp
                       height: 24 * dp
                       radius: 12 * dp
                       Text {
                           anchors.centerIn: parent
                           text: contactInbox
                           color: "white"
                           font.pixelSize: 11 * sp
                       }
                    }
                }

                Text {
                    anchors {left: image.right; verticalCenter: parent.verticalCenter; margins: 12 * dp}
                    font.pixelSize: theme.ContactsView.fontSize * sp
                    text: {

                        if (contactType === 1) {

                            "Contact request to <b>" + contactName + "</b>"
                        }
                        else
                        if (contactType === 2) {

                            if (contactAddCode) {

                                "Request for <b>" + contactAddCode + "</b> from <b>" + contactName + "</b>"
                            }
                            else {

                                "Contact request from <b>" + contactName + "</b>"
                            }
                        }
                        else
                        if (contactType === 3) {

                            "Contact request accepted by <b>" + contactName + "</b>"
                        }
                        else
                        if (contactType === 4) {

                            "Contact request rejected by <b>" + contactName + "</b>"
                        }
                        else {

                            contactName
                        }
                    }
                }

                Image {
                    id: status
                    anchors {right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 12 * dp}
                    source: contactStatus ? "/res/icons/" + dpiPrefix + "/led_green.png" : "/res/icons/" + dpiPrefix + "/led_red.png"
                    visible: !!contactId && contactType === 0
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: timer.start()
                    onPressed: spread.start(mouseX, wrap.height / 2)
                    onReleased: spread.finish()
                    onCanceled: spread.finish()

                    onPressAndHold: {

                        var contact = contactModel.get(index);

                        var actions;

                        if (contact.type === 0 && contact.name) {

                            actions = [{
                                actionId : "DELETE_CONTACT",
                                image    : "/res/icons/misc/drawable-" + dpiPrefix + "/ic_cancel_grey.png",
                                label    : "Delete"
                            }];
                        }

                        if (actions) {

                            actionPicker.show(actions, function(actionId) {

                                switch (actionId) {

                                    case "DELETE_CONTACT":

                                        busyBox.show("", function() {

                                            backend.deleteContact(contact.id, function() {

                                                busyBox.hide();

                                                contactModel.updateItems();
                                            });
                                        });

                                        break;
                                }
                            });
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1 * dp
                color: theme.ContactsView.separatorColor
            }
        }

        Controls.ScrollBar {
            id: scrollBar

            width: 20 * dp

            keepVisible: listView.moving

            trackItem: null

            handleItem: Rectangle {
                anchors {fill: parent; margins: 4}
                radius: 12
                color: "red"
            }

            onShow: wrapperItem.opacity = 1
            onHide: wrapperItem.opacity = 0

            onScroll: listView.contentY = pos

            wrapperItem.opacity: 0

            Behavior on wrapperItem.opacity {
                NumberAnimation {
                    duration: 250
                }
            }
        }

        onContentHeightChanged: scrollBar.contentSize = contentHeight
        onContentYChanged: scrollBar.contentPos = contentY
        onHeightChanged: scrollBar.update()
    }
}
