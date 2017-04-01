
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

    property var callback

    property string prevState

    property var mode;

    property var content

    property var activeContent

    property var activeModel

    property int selectedItemsCount: 0

    property var storeTypeActions: [
        {
            actionId : "FILE_SYSTEM",
            image : "/res/icons/" + dpiPrefix + "/ic_add_black.png",
            label : "File System"
        },
        {
            actionId : "LOCAL_STOAGE",
            image : "/res/icons/" + dpiPrefix + "/ic_add_black.png",
            label : "Local Store"
        }
    ];


    Component.onCompleted: {

        content = {

            FileSystem: {

                selection: new Utils.SelectionHelper(),

                clipboard: new Utils.SelectionHelper(),

                breadcrumbs: new Utils.BreadcrumbsHelper()
            },

            LocalStore: {

                selection: new Utils.SelectionHelper(),

                clipboard: new Utils.SelectionHelper(),

                breadcrumbs: new Utils.BreadcrumbsHelper()
            },

            RemoteStore: {

                selection: new Utils.SelectionHelper(),

                clipboard: new Utils.SelectionHelper(),

                breadcrumbs: new Utils.BreadcrumbsHelper()
            }
        };
    }

    function addItem() {

        createDirectory();
    }

    function copyItems() {

        if (activeContent.selection.count()) {

            activeContent.clipboard.selection = activeContent.selection.selection;

            clearSelection();
        }
    }

    function pasteItems() {

        if (content.FileSystem.clipboard.count() &&
            content.LocalStore.clipboard.count()) {

            actionPicker.show(storeTypeActions, function(actionId) {

                switch (actionId) {

                    case "FILE_SYSTEM":

                        pasteFromFileSystem();

                        break;

                    case "LOCAL_STORE":

                        pasteFromLocalStore();

                        break;
                }
            });
        }
        else
        if (content.FileSystem.clipboard.count()) {

            pasteFromFileSystem();
        }
        else
        if (content.LocalStore.clipboard.count()) {

            pasteFromLocalStore();
        }
    }

    function deleteItems() {

        dialog.confirm("Delete", "Do you really want to delete the selected items?", function() {

            if (dialog.accepted) {

                busyBox.show("", function() {

                    activeModel.deleteItems(activeContent.selection.keys(), function() {

                        clearSelection();

                        updateItems();

                        busyBox.hide();
                    });
                });
            }
        });
    }

    function createDirectory() {

        dialog.prompt("", "Create directory:", function() {

            if (dialog.accepted) {

                activeModel.createDirectory(dialog.inputText, activeModel.currentDir(), function() {

                    updateItems();
                });
            }
        });
    }

    function pasteFromFileSystem() {

        busyBox.show("", function() {

            activeModel.pasteFromFileSystem(
                    content.FileSystem.clipboard.keys(),
                    activeModel.currentDir(),
                    function(err) {

                content.FileSystem.clipboard.clear();

                selectionOptions.update();

                updateItems();

                busyBox.hide();
            });
        });
    }

    function pasteFromLocalStore() {

        busyBox.show("", function() {

            activeModel.pasteFromLocalStore(
                    content.LocalStore.clipboard.keys(),
                    activeModel.currentDir(),
                    function(err) {

                content.LocalStore.clipboard.clear();

                selectionOptions.update();

                updateItems();

                busyBox.hide();
            });
        });
    }

    function insertRemoteStoreSelection() {

        if (content.remoteStore.selection.count() &&
            (activeModel === fileSystemModel || activeModel === localStoreModel)) {

        }
    }

    function updateItems() {

        var cwd = activeModel.currentDir();

        activeModel.cd(cwd);

        activeModel.moreItems(browser.numItemsPage * 2, cwd);
    }

    function toggleSelection(index) {

        var itemData = activeModel.getItemData(index);

        if (itemData) {

            activeContent.selection.toggle(itemData.id, itemData);
        }
    }

    function clearSelection() {

        activeContent.selection.clear();

        selectedItemsCount = 0;

        selectionOptions.update();
    }

    function show(mode, callback) {

        if (!browser.tileSize) {

            browser.tileSize = browser.width / 3;
        }

        if (!contentView.callback) {

            contentView.callback = callback;

            contentView.prevState = views.state;
        }

        if (!mode) {

            mode = contentView.mode || 1;
        }

        contentView.mode = mode;

        if (mode === 1) {

            activeContent = content.FileSystem;

            clearSelection();

            browser.cd(null, fileSystemModel);
        }
        else
        if (mode === 2) {

            activeContent = content.LocalStore;

            clearSelection();

            browser.cd(null, localStoreModel);
        }


        clearSelection();

        if (!activeContent.breadcrumbs.count()) {

            breadcrumbs.init();
        }
        else {

            breadcrumbs.refresh();
        }

        views.state = "content";
    }

    function goBack() {

        if (callback) {

            views.state = prevState;

            callback = null;

            return true;
        }

        var item = activeContent.breadcrumbs.back();

        if (item) {

            browser.cd(item.dir);

            breadcrumbs.refresh();

            return true;
        }
    }

    clip: true

    Item {

        anchors {top: parent.top; left: parent.left; right: parent.right; bottom: selectionOptions.top}

        Controls.Browser {
            id: browser

            property int numItemsTotal

            onMoreData: {

                activeModel.moreItems(numItems, callback);
            }

            onLazyLoad: {

                var itemData = activeModel.getItemData(index);

                if (itemData) {

                    if (Utils.ImageFileRex.test(itemData.name)) {

                        var url = itemData.id + "?blobId=" + itemData.data + "&thumbSize=" + parseInt(browser.tileSize / dp) + "&source=" + mode + "&cache=1&async=1";

                        ImageService.loadImage(url, itemData, function(err, url, data) {

                            if (!err) {

                                item.image.source = "image://thumbs/" + url;
                            }

                            done(index);
                        });
                    }
                    else {

                        done(index);
                    }
                }
            }

            function cd(dir, model) {

                if (model) {

                    model.cd(dir);

                    activeModel = model;
                }
                else {

                    activeModel.cd(dir);
                }

                numItemsTotal = activeModel.numItemsTotal();

                moreData(browser.numItemsPage * 2, null);
            }

            anchors {top: breadcrumbs.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; /*fill: parent;*/ margins: 2 * dp}

            tileSize: 0

            //spacingUpper: breadcrumbs.height

            maximumFlickVelocity: 750 * dp

            model: activeModel

            delegate: Item {
                id: item

                property alias image : img

                property bool selected: selectedItemsCount > 0 && activeContent.selection.contains(itemId)

                width: browser.tileSize
                height: browser.tileSize

                Rectangle {
                    anchors {fill: parent; margins: 2 * dp}
                    clip: true

                    color: {

                        if (selected) {

                            "bisque"
                        }
                        else {

                            theme.ContentView.itemColor
                        }
                    }

                    Image {
                        id: img
                        anchors.centerIn: parent
                        opacity: item.selected ? 0.5 : 1

                        cache: false

                        source: {

                            if (type === 1) {
x
                                "/res/icons/" + dpiPrefix + "/ic_folder_grey.png";
                            }
                            else
                            if (type === 2 && Utils.ImageFileRex.test(name)) {

                                "/res/icons/" + dpiPrefix + "/file_image.png";
                            }
                            else
                            if (type === 2 && Utils.AudioFileRex.test(name)) {

                                "/res/icons/" + dpiPrefix + "/file_audio.png";
                            }
                            else
                            if (type === 2 && Utils.VideoFileRex.test(name)) {

                                "/res/icons/" + dpiPrefix + "/file_video.png";
                            }
                            else {

                                ""
                            }
                        }
                    }

                    Rectangle {
                        id: back
                        anchors {left: parent.left; right: parent.right; bottom: parent.bottom}
                        height: text.height + 8 * dp
                        color: theme.ContentView.itemColor
                        opacity: 0.75
                    }

                    Text {
                        id: text
                        anchors {left: back.left; right: back.right; verticalCenter: back.verticalCenter; margins: 4 * dp}
                        clip: true
                        text: name
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        maximumLineCount: 2
                        font.pixelSize: theme.ContentView.fontSize * sp
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Image {
                        anchors {top: parent.top; right: parent.right}
                        visible: selected
                        opacity: 0.75
                        source: "/res/icons/" + dpiPrefix + "/ic_check_box_black.png"
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                onClicked: {

                    var i = browser.indexAt(mouseX, mouseY);

                    if (i >= 0) {

                        var itemData = activeModel.getItemData(i);

                        if (selectedItemsCount === 0) {

                            if (itemData && itemData.type === 1) {

                                browser.cd(itemData.id)

                                activeContent.breadcrumbs.push({label: itemData.name, dir: itemData.id});

                                breadcrumbs.refresh();
                            }
                        }
                        else {

                            toggleSelection(i);
                        }

                        selectedItemsCount = activeContent.selection.count();
                    }
                }

                onPressAndHold: {

                    var i = browser.indexAt(mouseX, mouseY);

                    if (i >= 0) {

                        var itemData = activeModel.getItemData(i);

                        if (!(itemData.type === 1 && callback)) {

                            toggleSelection(i)

                            selectedItemsCount = activeContent.selection.count();
                        }
                    }
                }
            }

            Controls.ScrollBar {
                id: scrollBar

                width: 8 * dp

                interactive: false

                keepVisible: browser.moving

                trackItem: null

                handleItem: Rectangle {
                    anchors {fill: parent; margins: 2 * dp}
                    color: theme.ScrollBar.color
                }

                onShow: wrapperItem.opacity = 1
                onHide: wrapperItem.opacity = 0

                //onScroll: goto pos

                wrapperItem.opacity: 0

                Behavior on wrapperItem.opacity {
                    NumberAnimation {
                        duration: 250
                    }
                }
            }

            interactive: !scrollBar.scrolling

            onNumItemsTotalChanged: scrollBar.contentSize = Math.ceil(numItemsTotal / numItemsInRow) * tileSize
            onContentYChanged: scrollBar.contentPos = contentY
            onHeightChanged: scrollBar.update()
        }

        Rectangle {
            id: breadcrumbs

            property var items

            function init() {

                activeContent.breadcrumbs.clear();

                activeContent.breadcrumbs.push({label: "/", dir: activeModel.currentDir()});

                breadcrumbs.items = activeContent.breadcrumbs.items;
            }

            function refresh() {

                breadcrumbs.items = null;

                breadcrumbs.items = activeContent.breadcrumbs.items;
            }

            anchors {left: parent.left; right: parent.right}
            height: 40 * dp
            color: "white"

            Flickable {
                id: flick
                anchors {fill: parent; leftMargin: 20 * dp}
                contentWidth: row.width
                contentHeight: row.height
                flickableDirection: Flickable.HorizontalFlick

                Row {
                    id: row
                    height: flick.height

                    Repeater {
                        model: breadcrumbs.items

                        delegate: Item {

                            height: row.height
                            width: label.width + 12 * dp

                            Text {
                                id: label
                                anchors.centerIn: parent
                                text: modelData.label
                                font.bold: index === activeContent.breadcrumbs.index
                                font.pixelSize: 14 * sp
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {

                                    var item = activeContent.breadcrumbs.goto(index);

                                    browser.cd(item.dir);

                                    breadcrumbs.refresh();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Global.ActionBar {
        id: selectionOptions

        property bool copyCond

        property bool pasteCond

        property bool deleteCond

        function update() {

            copyCond =
                activeModel === fileSystemModel && content.FileSystem.selection.count() ||
                activeModel === localStoreModel && content.LocalStore.selection.count();

            pasteCond = content.FileSystem.clipboard.count() ||
                        content.LocalStore.clipboard.count();

            deleteCond =
                activeModel === fileSystemModel && content.FileSystem.selection.count() ||
                activeModel === localStoreModel && content.LocalStore.selection.count();
        }

        anchors {left: parent.left; right: parent.right; bottom: parent.bottom}
        height: selectedItemsCount > 0 || copyCond || pasteCond || deleteCond ? theme.ActionBar.height * dp : 0

        Global.ActionGroup {
            anchors {left: parent.left; leftMargin: 4 * dp}
            spacing: 12 * dp
            visible: !!callback

            Global.ActionButton {
                image: "/res/icons/" + dpiPrefix + "/ic_check_white.png"
                onClicked: {

                    var callback = contentView.callback;

                    goBack();

                    if (callback) {

                        callback(activeContent.selection.items());
                    }
                }
            }
        }

        Global.ActionGroup {
            anchors {left: parent.left; leftMargin: 4 * dp}
            spacing: 12 * dp
            visible: !callback

            Global.ActionButton {
                visible: selectedItemsCount > 0 || selectionOptions.copyCond
                image: "/res/icons/" + dpiPrefix + "/ic_content_copy_white.png"
                onClicked: {

                    copyItems();

                    clearSelection();
                }
            }

            Global.ActionButton {
                visible: selectionOptions.pasteCond
                image: "/res/icons/" + dpiPrefix + "/ic_content_paste_white.png"
                onClicked: pasteItems()
            }

            Global.ActionButton {
                visible: selectedItemsCount > 0 || selectionOptions.deleteCond
                image: "/res/icons/" + dpiPrefix + "/ic_delete_white.png"
                onClicked: deleteItems()
            }
        }

        Global.ActionGroup {
            anchors.right: parent.right

            Global.ActionButton {
                visible: selectedItemsCount > 0
                image: "/res/icons/" + dpiPrefix + "/ic_cancel_white.png"
                onClicked: clearSelection()
            }
        }
    }
}
