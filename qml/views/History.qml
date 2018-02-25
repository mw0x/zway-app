
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
import QtQuick.Layouts 1.3
import "../" as Global
import "../controls" as Controls
import "../utils.js" as Utils

Item {


    property var contact;

    property alias model: listView.model

    property var models

    property var message

    property var inputCache


    onContactChanged: console.log(JSON.stringify(contact))


    Component.onCompleted: {

        models = {};

        inputCache = {};

        function setMessage(message, resource) {

            var model;

            if (contact &&
                (message.dst === contact.id ||
                (message.dst === backend.accountId() && message.src === contact.id))) {

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

        if (!contactId) {

            return;
        }

        // save current context

        /*
        if (contactId) {

            inputCache[contactId] = {
                text   : messageText.text,
                cursor : messageText.textEdit.cursorPosition,
                state  : historyView.state,
            };
        }
        */

        // get history model

        var model = models[contactId];

        if (!model) {

            model = backend.latestHistoryModel(contactId);

            if (model) {

                historyView.contact = backend.getContact(contactId);

                historyView.model = model;

                models[contactId] = model;

                views.state = "history";

                busyBox.show("", function() {

                    model.updateItems(function() {

                        busyBox.hide();


                        clearMessage();


                        // restore context

                        /*
                        if (inputCache[contactId]) {

                            messageText.text = inputCache[contactId].text;

                            messageText.textEdit.cursorPosition = inputCache[contactId].cursor;

                            state = inputCache[contactId].state;
                        }
                        else {

                            messageText.text = "";

                            state = "";
                        }
                        */

                    });
                });
            }
        }
        else {

            historyView.contact = backend.getContact(contactId);

            historyView.model = model;

            views.state = "history";
        }

        backend.resetInbox(contactId);
    }

    function goBack() {

        contactView.show();

        return true;
    }

    function clearHistory() {

        dialog.confirm("Delete", "Do you really want to delete all items?", function() {

            if (dialog.accepted) {

                busyBox.show("", function() {

                    var historyId = backend.latestHistoryId(historyView.contact.id);

                    backend.deleteHistory(historyId, function() {

                        var model = backend.latestHistoryModel(historyView.contact.id);

                        historyView.models[historyView.contact.id] = model;

                        historyView.model = model;

                        historyView.model.updateItems();

                        clearMessage();

                        busyBox.hide();

                        callback();
                    });
                });
            }
        });
    }

    function clearMessage() {

        message = {
            dst       : contact.id,
            text      : "",
            resources : []
        };

        messageText.text = "";
    }

    function clear() {

        clearHistory();
    }

    function sendMessage() {

        Qt.inputMethod.commit();

        var plainText = messageText.plainText();

        // remove invisible char

        if (plainText.charCodeAt(0) === 8204) {

            plainText = plainText.slice(1);
        }
        else
        if (plainText.charCodeAt(plainText.length - 1) === 8204) {

            plainText = plainText.slice(0, plainText.length - 1);
        }

        plainText = plainText.trim();

        var text = messageText.text.replace(/\n/g, '');

        processResources(text);

        if (plainText.length || message.resources.length) {

            message.text = processMessageText(text, true);

            backend.postMessage(message);

            clearMessage();
        }
    }

    function processResources(text) {

        if (message.resources.length) {

            var i = message.resources.length;

            while (i--) {

                var resource = message.resources[i];

                var s = 'href=".*' + resource.id.toString().replace(/[-\/\\^$*+?.()|[\]{}]/g, '\\$&');

                var f = text.search(new RegExp(s));

                if (f === -1) {

                    message.resources.splice(i, 1);
                }
            }
        }
    }

    function processMessageText(text, mode) {

        var res = text;

        // remove some stuff

        res = res.replace(/<\/a>(\s*)<\/p>/g, "</a></p>");

        res = res.replace(/(font-family:'[^']+'|margin-\w+:[^;]+);\s*/g, "");

        // adjust font size values

        res = res.replace(/font-size:([0-9]+)(?:px|pt)?;/g, function(a,b) {

            return "font-size:" + Math.abs(!mode ? parseInt(b) * sp : parseInt(b) / sp) + "px;";
        });

        if (mode) {

            // process urls inside body

            res = res.replace(/<body[^>]*>(.+)<\/body>/, function(a, b, c) {

                return b.replace(/(https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b(?:[-a-zA-Z0-9@:%_\+.~#?&//=]*))/g, function(a, b) {

                    return '<a href="' + b + '">' + b + '</a>';
                });
            });
        }

        return res;
    }

    function processTime(time) {

        return new Date(time * 1000).toTimeString();
    }

    function doInsert(mode) {

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

                    a = '<a href="' + res.id + '">' + res.name + '</a>&nbsp;';
                }

                messageText.edit.insert(messageText.edit.selectionStart, a);
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

    Component {
        id: listViewDelegate

        Row {
            id: row

            property real textWidth: 0

            readonly property bool ownMessage: messageSrc === backend.accountId()

            padding: listView.messagePadding
            spacing: listView.messagePadding

            anchors.right: ownMessage ? parent.right : undefined

            Rectangle {
                id: avatar
                visible: !ownMessage
                width: listView.avatarSize
                height: listView.avatarSize
                radius: listView.avatarRadius
                color: contact.color

                Text {
                    anchors.centerIn: parent
                    text: contact.name.substr(0, 1)
                    font.pixelSize: 16 * sp
                    color: "white"
                }
            }

            Row {
                topPadding: !ownMessage ? listView.messageWrapTopOffset : 0
                layoutDirection: ownMessage ? Qt.RightToLeft : Qt.LeftToRight

                Image {
                    id: arrow
                    anchors.top: !ownMessage ? wrap.top : undefined
                    anchors.bottom: ownMessage ? wrap.bottom : undefined
                    anchors.margins: listView.messageWrapRadius
                    source: "/res/icons/" + dpiPrefix + "/bubble_arrow_" + (!ownMessage ? "left" : "right") + ".png"
                }

                Rectangle {
                    id: wrap
                    width: col2.width
                    height: col2.height
                    radius: listView.messageWrapRadius
                    color: !ownMessage ? "#F2F5A9" : "#F6E3CE"

                    Column {
                        id: col2
                        padding: listView.messageWrapPadding
                        spacing: listView.messageWrapPadding

                        Text {
                            id: text1
                            width: row.textWidth > listView.width - listView.messageWrapLeftOffset ? listView.width - listView.messageWrapLeftOffset : row.textWidth
                            wrapMode: row.textWidth > listView.width - listView.messageWrapLeftOffset ? Text.Wrap : Text.NoWrap
                            textFormat: Text.RichText
                            text: processMessageText(messageText)
                            font.pixelSize: theme.HistoryView.Message.fontSize * sp
                            onTextChanged: textWidth = text1.paintedWidth
                            onLinkActivated: {

                                if (link.indexOf("http") === 0) {

                                    Qt.openUrlExternally(link);
                                }

                            }
                        }

                        Row {
                            spacing: listView.messageWrapPadding

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

            Component.onCompleted: textWidth = text1.paintedWidth
        }
    }

    ListView {
        id: listView

        readonly property real avatarSize: 44 * dp
        readonly property real avatarRadius: 22 * dp

        readonly property real arrowWidth: 9 * dp
        readonly property real arrowHeight: 12 * dp

        readonly property real messagePadding: 6 * dp
        readonly property real messageWrapRadius: 8 * dp
        readonly property real messageWrapPadding: 8 * dp
        readonly property real messageWrapTopOffset: avatarSize / 2 - arrowHeight / 2 - messageWrapRadius
        readonly property real messageWrapLeftOffset: messagePadding * 3 + messageWrapPadding * 2 + arrowWidth * 2 + avatarSize

        anchors {top: parent.top; left: parent.left; right: parent.right; bottom: messageBox.top}
        clip: true
        boundsBehavior: ListView.DragOverBounds
        verticalLayoutDirection: ListView.BottomToTop
        delegate: listViewDelegate
    }

    Item {
        id: messageBox

        anchors {left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: wnd.virtualKeyboardDelta}

        height: messageWrap.height + 12 * dp

        Rectangle {
            id: messageWrap

            readonly property real minHeight: messageText.lineHeight * 2

            anchors {left: parent.left; right: messageButtons.left; bottom: parent.bottom; margins: 6 * dp}

            height: (messageText.height < minHeight ? minHeight : messageText.height) + 12 * dp

            color: theme.HistoryView.MessageText.backgroundColor

            radius: theme.HistoryView.MessageText.borderRadius * dp

            border.color: theme.HistoryView.MessageText.borderColor

            Controls.TextBox {
                id: messageText

                anchors {left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 6 * dp}

                focus: true

                // fix to get text extents updated properly when composing
                // which is not working if the document is empty
                // so add invisible char
                edit.onLengthChanged: { if (edit.length === 0) text = "&zwnj;"}

                edit.textFormat: TextEdit.RichText
                edit.font.pixelSize: theme.HistoryView.MessageText.fontSize * sp

                edit.cursorDelegate: Rectangle {
                    height: messageText.edit.font.pixelSize + 4 * dp
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
        }

        Row {
            id: messageButtons
            anchors {right: messageBox.right; verticalCenter: messageBox.verticalCenter}

            Global.ActionButton {
                id: attachButton
                image: "/res/icons/" + dpiPrefix + "/ic_action_new_attachment_black.png"
                onClicked: doInsert()
            }

            Global.ActionButton {
                id: sendButton
                image: "/res/icons/" + dpiPrefix + "/ic_action_send_now_black.png"
                onClicked: sendMessage()
            }
        }
    }

    /*
    Row {
        id: messageButtons1
        anchors {left: back.left; verticalCenter: back.verticalCenter}

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
    }
    */

    Keys.onBackPressed: goBack()
}
