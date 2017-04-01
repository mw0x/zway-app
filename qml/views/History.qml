
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
import "../" as Global
import "../controls" as Controls
import "../utils.js" as Utils

Item {

    property var contactId

    property var contact;

    property alias model: listView.model

    property alias messageInput: messageText

    property var models

    property var message

    property var messages

    property var inputCache


    Component.onCompleted: {

        models = {};

        messages = {};

        inputCache = {};

        function setMessage(message, resource) {

            var model;

            if (message.dst === contactId ||
                (message.dst === backend.accountId() && message.src === contactId)) {

                model = historyView.model;
            }
            else {

                model = models[message.src];
            }

            if (model) {

                if (model.messageIndex(message.id) === -1) {

                    model.append(message);
                }
                else {

                    model.update(message);
                }
            }
        }

        backend.messageIncoming.connect(setMessage);

        backend.messageOutgoing.connect(setMessage);

        backend.messageDelivered.connect(setMessage);

        backend.resourceReceived.connect(setMessage);
    }

    function show(contactId) {

        // save current context

        if (contactId) {

            inputCache[contactId] = {
                text   : messageText.text,
                cursor : messageText.textEdit.cursorPosition,
                state  : historyView.state,
            };
        }

        // get history model

        var model = models[contactId];

        if (!model) {

            model = backend.latestHistoryModel(contactId);

            if (model) {

                models[contactId] = model;

                historyView.model = model;

                historyView.contactId = contactId;

                historyView.contact = backend.getContact(contactId);

                views.state = "history";

                busyBox.show("", function() {

                    model.updateItems(function() {

                        busyBox.hide();

                        setMessage();

                        // restore context

                        if (inputCache[contactId]) {

                            messageText.text = inputCache[contactId].text;

                            messageText.textEdit.cursorPosition = inputCache[contactId].cursor;

                            state = inputCache[contactId].state;
                        }
                        else {

                            messageText.text = "";

                            state = "";
                        }
                    });
                });
            }
        }
        else {

            historyView.model = model;

            historyView.contactId = contactId;

            historyView.contact = backend.getContact(contactId);

            views.state = "history";
        }

        backend.resetInbox(contactId);
    }

    function goBack() {

        if (state === "expanded") {

            state = "";
        }
        else {

            contactView.show();
        }

        return true;
    }

    function setMessage(reset) {

        if (!messages[contactId] || reset) {

            message = messages[contactId] = {
                dst       : contactId,
                text      : "",
                resources : []
            };
        }
        else {

            message = messages[contactId];
        }
    }

    function clearHistory() {

        busyBox.show("", function() {

            var historyId = backend.latestHistoryId(historyView.contactId);

            backend.deleteHistory(historyId, function() {

                historyView.messages = {};

                var model = backend.latestHistoryModel(historyView.contactId);

                historyView.models[historyView.contactId] = model;

                historyView.model = model;

                historyView.model.updateItems();

                messageText.textEdit.text = "";

                busyBox.hide();

                callback();
            });
        });
    }

    function clearMessage() {

        setMessage(true);

        messageText.text = "";
    }

    function clear() {

        if (state === "expanded") {

            clearMessage();
        }
        else {

            clearHistory();
        }
    }

    function numMessageResources() {

        return message.resources ? message.resources.length : 0;
    }

    function sendMessage() {

        Qt.inputMethod.commit();

        if (messageText.plainText().trim().length || numMessageResources()) {

            message.text = processMessageText(messageText.text, true);

            backend.postMessage(message);

            clearMessage();

            state = "";
        }
    }

    function processMessageText(text, mode) {

        if (!text) {

            console.debug("processMessageText: undefined 'text' arg")

            return "";
        }

        var res = text;

        // remove some stuff

        res = res.replace(/<\/a>(\s*)<\/p>/g, "</a></p>");

        res = res.replace(/(font-family:'[^']+'|margin-\w+:[^;]+);\s*/g, "");

        // adjust font size values

        res = res.replace(/font-size:([0-9]+)(?:px|pt)?;/g, function(a,b) {

            return "font-size:" + Math.abs(!mode ? parseInt(b) * sp : parseInt(b) / sp) + "px;";
        });

        return res;
    }

    function processTime(time) {

        return new Date(time * 1000).toTimeString();
    }

    ListView {
        id: listView

        property real messageMargin: 6 * dp
        property real messagePadding: 4 * dp

        readonly property real innerWidth: listView.width - messageMargin * 2 - messagePadding * 2

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 250 }
            NumberAnimation { property: "scale"; from: 0; to: 1.0; duration: 250 }
        }

        displaced: Transition {
            NumberAnimation { properties: "x,y"; duration: 250 }
        }

        onCountChanged: {

            if (count === 1) {

                currentIndex = 1;
            }

            currentIndex = 0;
        }

        anchors {top: parent.top; left: parent.left; right: parent.right; bottom: back2.top}
        clip: true

        boundsBehavior: ListView.DragOverBounds
        verticalLayoutDirection: ListView.BottomToTop

        delegate: Item {
            width: listView.width
            height: wrapper.height + listView.messagePadding * 4

            property bool ownMessage: messageSrc === backend.accountId()

            Text {
                id: message
                visible: false
                textFormat: Text.RichText
                text: processMessageText(messageText)
                font.pixelSize: theme.HistoryView.Message.fontSize * sp
            }

            Rectangle {
                id: avatarBox
                anchors {top: parent.top; left: parent.left; leftMargin: listView.messagePadding * 2}
                visible: !ownMessage
                width: 44 * dp
                height: 44 * dp
                radius: 22 * dp
                color: contact.color

                Text {
                    anchors.centerIn: parent
                    text: contact.name.substr(0, 1)
                    font.pixelSize: 16 * sp
                    color: "white"
                }
            }

            Image {
                id: arrowImage
                anchors {
                    left: !ownMessage ? avatarBox.right : undefined
                    right: ownMessage ? parent.right : undefined
                    bottom: ownMessage ? wrapper.bottom : undefined
                    leftMargin: !ownMessage ? listView.messagePadding : undefined
                    rightMargin: ownMessage ? listView.messagePadding * 2 : undefined
                    bottomMargin: ownMessage ? listView.messagePadding * 2 : undefined
                    verticalCenter: !ownMessage ? avatarBox.verticalCenter : undefined
                }
                source: "/res/icons/" + dpiPrefix + "/bubble_arrow_" + (!ownMessage ? "left" : "right") + ".png"
            }

            Rectangle {
                id: wrapper

                anchors {
                    top: !ownMessage ? arrowImage.top : undefined
                    topMargin: -listView.messagePadding * 2
                    left  : !ownMessage ? arrowImage.right : undefined
                    right : ownMessage ? arrowImage.left  : undefined
                }

                width: col.width + listView.messagePadding * 5
                height: col.height + listView.messagePadding * 4
                color: !ownMessage ? "#F2F5A9" : "#F6E3CE"
                radius: theme.HistoryView.Message.borderRadius * dp

                Column {
                    id: col
                    spacing: 6 * dp
                    anchors.centerIn: parent

                    Text {
                        width: message.width < listView.innerWidth ? message.width : listView.innerWidth
                        wrapMode: Text.Wrap
                        textFormat: Text.RichText
                        text: message.text
                        font: message.font

                        onLinkActivated: {

                            imageScreen.show(link);
                        }
                    }

                    Row {
                        anchors {
                            left: ownMessage ? parent.left : undefined
                            right: !ownMessage ? parent.right : undefined
                        }

                        spacing: 6 * dp

                        Text {
                            id: status
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 10 * sp
                            color: "#5C5C5C"

                            text: {

                                if (messageStatus === 1)
                                    "Incoming"
                                else
                                if (messageStatus === 2 ||
                                    messageStatus === 3)
                                    "Outgoing"
                                else
                                if (messageStatus === 4 ||
                                    messageStatus === 5) processTime(messageTime)
                                else
                                    "Idle"
                            }
                        }

                        AnimatedImage {
                            id: spinner
                            anchors.verticalCenter: parent.verticalCenter
                            visible: messageStatus === 1 || messageStatus === 2 || messageStatus === 3
                            source: "/res/spinners/" + dpiPrefix + "/spinner.gif"
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: back1
        anchors.fill: parent
        color: "#d6d6d6"
        visible: false
    }

    Item {
        id: back2
        anchors {left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: wnd.virtualKeyboardDelta}
        height: messageText.defaultHeight + 12 * dp
    }

    Controls.TextBox {
        id: messageText

        property int defaultHeight: (textEdit.font.pixelSize + 4 * dp) * 2 + padding * 2

        anchors {left: back2.left; right: messageButtons2.left; verticalCenter: back2.verticalCenter; margins: 6 * dp}

        // tried to handle that by PropertyChanges but 'color' is not reset
        // when switching back to default state?!
        border.color: historyView.state !== "expanded" ? theme.HistoryView.MessageText.borderColor : "#00000000"
        color:  historyView.state !== "expanded" ? theme.HistoryView.MessageText.backgroundColor : "#00000000"

        focus: true
        height: defaultHeight
        padding: theme.HistoryView.MessageText.padding * dp
        radius: theme.HistoryView.MessageText.borderRadius * dp
        textEdit.font.pixelSize: theme.HistoryView.MessageText.fontSize * sp
        textEdit.wrapMode: TextEdit.Wrap
        textEdit.textFormat: TextEdit.RichText

        textEdit.selectByMouse: true
        textEdit.selectionColor: theme.HistoryView.MessageText.selectionColor

        textEdit.cursorDelegate: Rectangle {
            height: messageText.textEdit.font.pixelSize + 4 * dp
            width: 1 * dp
            color: "#5B5B5B"

            Timer {
                interval: 500
                running: messageText.visible
                repeat: true
                onTriggered: visible = !visible
            }
        }

        Keys.onReturnPressed: {

            if (!(event.modifiers & Qt.ShiftModifier)) {

                event.accepted = false;
            }
            else {

                sendMessage();
            }
        }
    }

    Row {
        id: messageButtons1
        anchors {left: back2.left; verticalCenter: back2.verticalCenter}

        Global.ActionButton {
            id: addButton1
            image: "/res/icons/" + dpiPrefix + "/ic_add_black.png"
            visible: false
            onClicked: {

                var actions = [];

                //if (QtMultimedia.availableCameras.length > 1) {

                    QtMultimedia.availableCameras.forEach(function(it, ix) {

                        actions.push({
                            image    : "ic_camera_alt_grey.png",
                            index    : ix,
                            label    : it.displayName,
                            actionId : "CAMERA_" + (ix + 1)
                        });
                    });
                //}
                //else {


                //}

                actionPicker.show(actions, function(actionId) {

                    switch (actionId) {

                        case "CAMERA_1":
                        case "CAMERA_2":

                            var dev = QtMultimedia.availableCameras[action.index];

                            cameraView.show(dev.deviceId, function(resourceId, name) {

                                if (resourceId) {

                                    message.resources.push({
                                        id   : resourceId,
                                        type : 1,
                                        name : name
                                    });

                                    var a = '<a href="' + resourceId + '"><img src="image://resources/' + resourceId + '"></img></a><br>';

                                    messageText.textEdit.insert(messageText.textEdit.selectionStart, a);

                                    Qt.inputMethod.show();
                                }
                            });

                            break;
                    }
                });
            }
        }

        Global.ActionButton {
            id: addButton2
            image: "/res/icons/" + dpiPrefix + "/ic_add_black.png"
            visible: false
            onClicked: {

                function insert(items) {

                    var i=0;

                    function insertResource(res) {

                        var resourceId = res.path || res.id;

                        message.resources.push(res);

                        var a;

                        if (Utils.ImageFileRex.test(res.name)) {

                            a = '<a href="' + res.thumbUrl + '"><img cache=0 src="' + res.thumbUrl + '"/></a><br>';
                        }
                        else {

                            a = '<a href="' + res.thumbUrl + '">' + res.name + '</a>&nbsp;';
                        }

                        messageText.textEdit.insert(messageText.textEdit.selectionStart, a);
                    }

                    function next() {

                        var it = items[i++];

                        if (it) {

                            if (Utils.ImageFileRex.test(it.name)) {

                                var url = it.id + "?blobId=" + (it.data || 0) + "&thumbSize=120" + "&source=" + it.origin + "&cache=1";

                                ImageService.loadImage(url, Utils.ObjHelper.clone(it), function(err, url, data) {

                                    if (!err) {

                                        data.thumbUrl = "image://thumbs/" + url;

                                        insertResource(data);
                                    }
                                    else {

                                        // TODO: error dialog here
                                    }

                                    next();
                                });
                            }
                            else {

                                insertResource(it);

                                next();
                            }
                        }
                    }

                    next();
                }

                // open browser view in callback mode

                contentView.show(0, function(items) {

                    // insert selected items

                    insert(items);
                });
            }
        }
    }

    Row {
        id: messageButtons2
        anchors {right: back2.right; verticalCenter: back2.verticalCenter}

        Global.ActionButton {
            id: attachButton
            image: "/res/icons/" + dpiPrefix + "/ic_action_new_attachment_black.png"
            onClicked: historyView.state = "expanded"
        }

        Global.ActionButton {
            id: sendButton
            image: "/res/icons/" + dpiPrefix + "/ic_action_send_now_black.png"
            onClicked: sendMessage()
        }
    }

    states: [
        State {
            name: "search"
            PropertyChanges { target: back1; visible: false }
            PropertyChanges { target: back2; visible: false }
            PropertyChanges { target: addButton1; visible: false }
            PropertyChanges { target: addButton2; visible: false }
            PropertyChanges { target: attachButton; visible: false }
            PropertyChanges { target: sendButton; visible: false }
            PropertyChanges { target: messageText; visible: false }
        },
        State {
            name: "expanded"

            AnchorChanges {
                target: messageText
                anchors {top: historyView.top; left: historyView.left; right: historyView.right; bottom: back2.top; verticalCenter: undefined}
            }

            PropertyChanges {
                target:  messageText
                anchors.margins: 12 * dp
                //border.color: "#00000000"
                //color: "#00000000"
            }

            PropertyChanges { target: back1; visible: true }
            PropertyChanges { target: back2; visible: false }
          //PropertyChanges { target: addButton1; visible: true }
            PropertyChanges { target: addButton2; visible: true }
            PropertyChanges { target: attachButton; visible: false }
            PropertyChanges { target: views; actionBarState: "history_expanded" }
        }
    ]

    Keys.onBackPressed: goBack()
}
