
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

Item {
    id: scrollBar

    property bool interactive: true
    property bool keepVisible: false
    property real contentSize
    property real contentPos
    property real ratio

    property alias wrapperItem: wrapper

    property var trackItem: Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.75
    }

    property var handleItem: Rectangle {
        anchors.fill: parent
        color: "green"
    }

    readonly property bool scrolling: mouseArea.dragging

    signal show
    signal hide
    signal scrollStart
    signal scrollEnd
    signal scroll(real pos)

    onContentSizeChanged: update()
    onContentPosChanged: update()

    onKeepVisibleChanged: {

        if (!keepVisible) {

            hide();
        }
        else
        if (ratio < 1) {

            show();
        }
    }

    anchors {top: parent.top; right: parent.right; bottom: parent.bottom}
    clip: true

    function update() {

        if (!mouseArea.dragging) {

            ratio = scrollBar.height / scrollBar.contentSize;

            if (ratio < 1) {

                handleWrapper.height = scrollBar.height * ratio;

                handleWrapper.y = Math.max(0, Math.min(scrollBar.height - handleWrapper.height, scrollBar.contentPos * ratio));
            }
        }
    }

    MouseArea {
        id: mouseArea

        function setPosition(y) {

            handleWrapper.y = Math.max(0, Math.min(scrollBar.height - handleWrapper.height, -offset + y));

            scroll(handleWrapper.y / ratio);
        }

        property bool dragging: false

        property real offset

        property real startY

        anchors.fill: parent

        enabled: scrollBar.interactive

        hoverEnabled: true

        onEntered: {

            if (!dragging && !keepVisible && ratio < 1) {

                show();
            }
        }

        onExited: {

            if (!dragging && !keepVisible && ratio < 1) {

                hide();
            }
        }

        onPressed: {

            if (mouseY >= handleWrapper.y && mouseY <= handleWrapper.y + handleWrapper.height) {

                dragging = true;

                startY = mouseY;

                offset = mouseY - handleWrapper.y;

                scrollStart();
            }
            else {

                startY = mouseY;

                offset = 0;

                setPosition(mouseY - handleWrapper.height / 2)
            }
        }

        onReleased: {

            if (dragging) {

                dragging = false;

                scrollEnd();

                // slide out if scrollbar doesn't contain the mouse anymore

                if (!containsMouse) {

                    hide();
                }
            }
        }

        onMouseYChanged: {

            if (dragging) {

                setPosition(mouseY);
            }
        }
    }

    Item {
        id: wrapper
        width: parent.width
        anchors {top: parent.top; bottom: parent.bottom}

        Item {
            id: trackWrapper
            anchors.fill: parent
        }

        Item {
            id: handleWrapper
            anchors {left: parent.left; right: parent.right}
        }
    }

    Component.onCompleted: {

        if (trackItem) trackItem.parent = trackWrapper;
        if (handleItem) handleItem.parent = handleWrapper;
    }
}
