
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
    id: navigationDrawer

    default property alias content: container.children

    readonly property alias contentX: container.x

    property alias dimmerColor: dimmer.color

    property var swipeArea

    property real contentWidth: 240

    property real offset: 20

    property bool swipe: false

    property int status: 0

    property bool interactive: true

    onSwipeAreaChanged: {

        swipeArea.dragging.connect(onDragging);

        swipeArea.dragEnded.connect(onDragEnded);

        swipeArea.leftSwipe.connect(onLeftSwipe);

        swipeArea.rightSwipe.connect(onRightSwipe);
    }

    function onDragging(deltaX) {

        if (!interactive) return;

        if (!swipe && !anim.running) {

            if (status === 1) {

                var x = offset - mouse.lastX;

                if (deltaX > x && deltaX < container.width - mouse.lastX) {

                    container.x = -container.width + offset + deltaX - x;
                }
            }

            if (status === 2) {

                if (deltaX + mouse.lastX < 0) {

                    container.x = deltaX + mouse.lastX;
                }
            }
        }
    }

    function onDragEnded(deltaX) {

        if (!interactive) return;

        if (!swipe && !anim.running) {

            if (container.x < -contentWidth / 2) {

                hide();
            }
            else {

                show();
            }
        }
        else
        if (mouse.lastX + deltaX < offset) {

            hide();
        }

        mouse.lastX = 0;

        swipe = false;
    }

    function onLeftSwipe() {

        if (!interactive) return;

        if (status === 2) {

            swipe = true;

            hide();
        }
    }

    function onRightSwipe() {

        if (!interactive) return;

        if (status === 1) {

            swipe = true;

            show();
        }
    }

    function show() {

        anim.stop();

        anim.to = 0;

        anim.start();

        status = 2;
    }

    function hide() {

        anim.stop();

        anim.to = -contentWidth

        anim.start();

        status = 0;
    }

    anchors.fill: parent

    Rectangle {
        id: dimmer
        anchors.fill: parent
        color: "black"
        opacity: (1 - (-container.x / container.width)) / 2;
    }

    NumberAnimation {
        id: anim
        target: container
        property: "x"
        duration: 250
    }

    Item {
        id: container
        anchors {top: parent.top; bottom: parent.bottom}
        width: contentWidth
        x: -contentWidth
    }

    MouseArea {
        id: mouse

        property real lastX

        anchors {top: parent.top; left: container.right; bottom: parent.bottom}
        width: navigationDrawer.status === 2 ? navigationDrawer.width - navigationDrawer.contentWidth : offset
        enabled: interactive
        x: 0

        onPressed: {

            lastX = mouseX;

            if (navigationDrawer.status !== 2) {

                anim.stop();

                anim.to = -navigationDrawer.contentWidth + offset;

                anim.start();

                navigationDrawer.status = 1;
            }
        }

        onReleased: {

            if (navigationDrawer.status !== 2) {

                navigationDrawer.hide();
            }
        }

        onClicked: {

            navigationDrawer.hide();
        }
    }
}
