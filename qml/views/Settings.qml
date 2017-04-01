
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
import "../controls" as Controls
import "../views/settings" as Settings

Item {

    property string prevState;

    property var config;

    function activeSettings() {

        var res = {};

        for (var i in settingsModel.children) {

            var item = settingsModel.children[i];

            if (item.active) {

                res[item.name] = item;
            }
        }

        return res;
    }

    function show() {

        prevState = views.state;

        config = backend.getConfig() || {};

        var s = activeSettings();
        for (var i in s) s[i].set(config[i]);

        views.state = "settings";
    }

    function goBack() {

        var config = {};

        var s = activeSettings();

        for (var i in s) config[i] = s[i].get();

        busyBox.show("", function() {

            backend.setConfig(config, function(err) {

                busyBox.hide();

                views.state = prevState;
            });
        });

        return true;
    }

    VisualItemModel {
        id: settingsModel
        Settings.CheckBoxSetting {
            width: settingsList.width;
            id: findByName;
            name: "findByName";
            text: "Make me findable by name"}
        Settings.CheckBoxSetting {
            width: settingsList.width;
            id: findByPhone;
            name: "findByPhone";
            text: "Make me findable by phone";
            active: Qt.platform.os === "android" /*|| Qt.platform.os === "ios"*/}
        Settings.CheckBoxSetting {
            width: settingsList.width;
            id: notifyStatus;
            name: "notifyStatus";
            text: "Notify contacts about my status"}
    }

    ListView {
        id: settingsList

        anchors.fill: parent

        model: settingsModel
    }
}
