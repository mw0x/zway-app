
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

    default property alias content: content.children

    property var views;

    property var currentView

    property int currentIndex

    signal viewChanged(var view, int index)

    function isCurrentView() {

        for (var i=0; i<arguments.length; i++) {

            if (currentView === arguments[i]) {

                return true;
            }
        }

        return false;
    }

    function showView(view) {

        if (typeof view === "number") {

            view = content.children[view];
        }
        else
        if (typeof view === "string") {

            view = content.viewMap[view];
        }

        if (view && view !== currentView) {

            view.opacity = 0;

            for (var i in content.children) {

                if (view === content.children[i]) {

                    currentIndex = i;

                    break;
                }
            }

            if (viewAnimation.running) {

                viewAnimation.complete();
            }

            currentViewAnimation.target = currentView;
            currentViewAnimation.to = 0;

            nextViewAnimation.target = view;
            nextViewAnimation.to = 1;

            viewAnimation.start();

            currentView = view;

            viewChanged(currentView, currentIndex);
        }
    }

    SequentialAnimation {
        id: viewAnimation

        property int count: 0

        PropertyAnimation {
            id: currentViewAnimation
            duration : 250
            property: "opacity"
            easing.type: Easing.InQuad
        }

        PropertyAnimation {
            id: nextViewAnimation
            duration : 250
            property: "opacity"
            easing.type: Easing.InQuad
        }

        onRunningChanged: {

            if (++count === 2) {

                currentViewAnimation.target.visible = false;

                count = 0;
            }
        }
    }

    Item {
        id: content
        anchors.fill: parent
    }

    Component.onCompleted: {

        if (content.children.length) {

            currentView = content.children[0];

            currentIndex = 0;

            views = [];

            for (var i in content.children) {

                content.children[i].visible = (i === "0");

                views.push(content.children[i]);
            }

            views.forEach(function(item) {

                item.visibleChanged.connect(function() {

                    if (item.visible) {

                        showView(item);
                    }
                });
            });
        }
    }
}

