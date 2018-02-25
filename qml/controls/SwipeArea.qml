
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
    id: area

    default property alias content: container.children

    property alias flickableDirection: flick.flickableDirection

    property alias pressDelay: flick.pressDelay

    property real thresholdX: 10

    property real thresholdTime: 150

    signal dragStarted

    signal dragEnded(real deltaX, real deltaY)

    signal dragging(real deltaX, real deltaY)

    signal leftSwipe(real velocity)

    signal rightSwipe(real velocity)

    Flickable {
        id: flick

        property real lastX
        property real lastY
        property real lastTime

        function center() {

            contentX = (contentWidth - width) / 2;
            contentY = (contentHeight - height) / 2;
        }

        anchors.fill: parent
        contentWidth: dummy.width
        contentHeight: dummy.height
        flickDeceleration: 0
        maximumFlickVelocity: 0
        boundsBehavior: Flickable.StopAtBounds

        onDragStarted: {

            lastX = contentX;
            lastY = contentY;

            lastTime = new Date().getTime();

            area.dragStarted();
        }

        onDragEnded: {

            var deltaX = lastX - contentX;
            var deltaY = lastY - contentY;

            var deltaTime = new Date().getTime() - lastTime;

            var velocityX = Math.abs(deltaX / deltaTime);
            var velocityY = Math.abs(deltaY / deltaTime);

            if (deltaTime < thresholdTime) {

                if (deltaX < -thresholdX) {

                    area.leftSwipe(velocityX)
                }
                else
                if (deltaX > thresholdX) {

                    area.rightSwipe(velocityX)
                }
            }

            area.dragEnded(deltaX, deltaY);
        }

        onContentXChanged: {

            if (dragging) {

                area.dragging(lastX - contentX, lastY - contentY);
            }
        }

        onMovementEnded: center()

        Item {
            id: dummy
            width: flick.width * 4
            height: flick.height * 4
        }

        Item {
            id: container
            width: flick.width
            height: flick.height
        }
    }

    Component.onCompleted: {

        container.parent = flick;

        flick.center();
    }
}
