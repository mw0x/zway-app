
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

Flickable {
    id: browser

    default property alias content: container.children

    property int tileSize: 100

    property int spacingUpper: 0

    property int spacingLower: 0

    property alias model: dataModel.model

    property alias delegate: dataModel.delegate

    readonly property int numItems: dataModel.count

    readonly property int numRows: Math.ceil(dataModel.count / numItemsInRow)

    readonly property int numRowsPossible: Math.ceil(height / tileSize) + 1

    readonly property int numItemsInRow: Math.floor(width / tileSize)

    readonly property int numItemsPossible: numRowsPossible * numItemsInRow

    readonly property int numItemsPage: Math.floor(height / tileSize) * numItemsInRow

    property int numRowsInvisibleUpper: 0

    property int numRowsInvisibleLower: 0

    property int numRowsVisible: 0

    readonly property int numItemsVisible: Math.min(numRowsVisible * numItemsInRow, numItems - (numRowsInvisibleUpper + numRowsInvisibleLower) * numItemsInRow)

    readonly property int contentHeightEx: contentHeight - spacingUpper - spacingLower

    signal moreData(int numItems, var done)

    signal lazyLoad(int index, var item, var done)

    function indexAt(x, y) {

        if (x > numItemsInRow * tileSize) {

            return -1;
        }

        var r = numRowsInvisibleUpper + Math.ceil(y / tileSize);

        var d1 = contentY > 0 ? tileSize - contentY % tileSize : 0;

        var d2 = parseInt(y % tileSize);

        if (d1 > 0 && d2 > d1) {

            r++;
        }

        var i = (r - 1) * numItemsInRow + Math.ceil(x / tileSize) - 1;

        return i < numItems ? i : -1;
    }

    function itemAt(index) {

        if (index >= 0 && index < items.children.length) {

            return items.children[index];
        }
    }

    onWidthChanged: items.check(true)

    onHeightChanged: items.check(true)

    onContentYChanged: items.check()

    onNumRowsChanged: {

        contentHeight = browser.numRows * browser.tileSize + browser.spacingUpper;

        if (numRows === 0) {

            items.reset();

            items.empty = true;
        }
        else
        if (numRows > 0 && items.empty) {

            items.check(true);

            items.empty = false;
        }
    }

    contentWidth: items.width

    flickableDirection: Flickable.VerticalFlick

    boundsBehavior: Flickable.DragOverBounds

    VisualDataModel {
        id: dataModel
    }

    Flow {
        id: items

        property bool empty: true

        property int upperOffset: 0

        property int lowerOffset: 0

        property int lazyIndex: 0

        property int lazyOffset: 0

        property var lazyIndexes

        property bool lazyLoading: false

        Component.onCompleted: {

            lazyIndexes = [];
        }

        function reset() {

            upperOffset = 0;

            lowerOffset = 0;

            lazyIndex = 0;

            lazyOffset = 0;

            lazyLoading = false;
        }

        function check(fullUpdate) {

            if (numRows <= 0 || tileSize <= 0 || contentHeightEx <= 0) {

                return;
            }

            var numRowsUpperLast = numRowsInvisibleUpper;

            var numRowsLowerLast = numRowsInvisibleLower;

            var numRowsUpper = Math.max(0, Math.floor(browser.contentY / tileSize));

            var numRowsLower = Math.max(0, Math.floor((browser.contentHeightEx - browser.height - browser.contentY) / tileSize));

            numRowsVisible = numRows - numRowsUpper - numRowsLower;

            var update = false;

            if (numRowsInvisibleUpper !== numRowsUpper) {

                if (numRowsUpper >= 0) {

                    numRowsInvisibleUpper = numRowsUpper;

                    update = true;
                }
                else {

                    numRowsInvisibleUpper = 0;
                }
            }

            if (numRowsInvisibleLower !== numRowsLower || numItemsVisible <= numItemsPage) {

                if (numRowsLower >= 0) {

                    numRowsInvisibleLower = numRowsLower;

                    if (numRowsLower === 0) {

                        moreData(numItemsPage, function(args) {

                        });
                    }
                    else {

                        update = true;
                    }
                }
                else {

                    numRowsInvisibleLower = 0;
                }
            }

            if (update || fullUpdate) {

                updateVisibilities(fullUpdate);

                lazyLoad()
            }
        }

        function updateVisibilities(fullUpdate) {

            var upperIndex = Math.max(0, numRowsInvisibleUpper - 1) * numItemsInRow;

            var lowerIndex = Math.max(0, numRows - numRowsInvisibleLower + 1) * numItemsInRow;

            if (upperIndex < upperOffset) {

                upperOffset = upperIndex;
            }

            if (fullUpdate) {

                upperOffset = 0;

                lowerOffset = 0;
            }

            for (var i=upperOffset; i<children.length - lowerOffset; i++) {

                if (children[i]) {

                    children[i].visible = i >= upperIndex && i < lowerIndex;
                }
            }

            upperOffset = upperIndex;
            lowerOffset = children.length - lowerIndex - numItemsInRow;
        }

        function lazyLoad() {

            if (!lazyLoading) {

                function next() {

                    var p = Math.min(numItems, (numRowsInvisibleUpper + numRowsVisible) * numItemsInRow);

                    var i = lazyOffset + lazyIndex;

                    if (p > i) {

                        lazyLoading = true;

                        if ((numRowsInvisibleUpper + numRowsVisible - Math.ceil(i / numItemsInRow)) >
                            (numItemsPage / numItemsInRow * 2)) {

                        }
                        //else {

                            browser.lazyLoad(i, children[i], function() {

                                lazyIndex++;

                                next();
                            });
                        //}
                    }
                    else {

                        lazyLoading = false;
                    }
                }

                next();
            }
        }

        y: Math.max(0, browser.numRowsInvisibleUpper - 1) * browser.tileSize + browser.spacingUpper

        width: browser.width

        Repeater {
            model: dataModel
        }
    }

    Item {
        id: container
        parent: browser
        anchors.fill: parent
    }
}
