
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

Rectangle {

    property var effect

    /*
    function startEffect(element, x, y) {

        if (effect) {

            var r = mapFromItem(element);

            effect.start(
                r.x + element.width / 2,
                r.y + element.height / 2
            );
        }
    }

    function finishEffect() {

        if (effect) {

            effect.finish();
        }
    }

    function cancelEffect() {

        if (effect) {

            effect.finish();
        }
    }
    */

    anchors {left: parent.left; right: parent.right}
    height: theme.ActionBar.height * dp
    color: theme.ActionBar.color
    clip: true
}

