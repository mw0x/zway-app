
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

.pragma library

var ImageFileRex = new RegExp('\.(ami|apx|bmp|bpg|brk|bw|cal|cals|cbm|cbr|cbz|cpt|cur|dds|dng|exr|fif|fpx|fxo|fxs|gbr|gif|giff|ico|iff|ilbm|lbm|iff|img|jbig2|jb2|jp2|jpc|j2c|j2k|jpx|jpg|jpeg|jpe|jfif|jng|jxr|wdp|hdp|kdc|koa|lbm|lwf|lwi|mac|miff|msk|msp|ncr|ngg|nlm|nmp|nol|oaz|oil|pat|pbm|pcd|pct|pcx|pdb|pdd|pgf|pgm|pic|pld|png|pnm|ppm|psd|pspimage|psp|qti|qtif|ras|raw|rgb|rgba|sgi|rle|tga|bpx|icb|pix|tif|tiff|webp|xbm|xcf|xpm|ai|cdr|cgm|cmx|des|design|dgn|dvg|dwg|dwf|dxf|emf|eps|fhX|fig|gbr|ger|gem|geo|mba|odg|pgf|tikz|plt|hpg|hp2|pl2|prn|ps|rvt|svg|swf|sxd|tvz|wmf|xaml|xar)$', 'i');

var AudioFileRex = new RegExp('\.(act|aif|aiff|aac|amr|ape|au|awb|dct|dss|dvf|flac|gsm|iklax|ivs|m4a|m4p|mmf|mp3|mpc|msv|ogg|oga|opus|ra|rm|raw|sln|tta|vox|wav|wma|wv)$', 'i');

var VideoFileRex = new RegExp('\.(webm|mkv|flv|vob|ogv|drc|mng|avi|mov|qt|wmv|yuv|rm|rmvb|asf|mp4|m4p|m4v|mpg|mp2|mpe|mpv|mpg|mpeg|m2v|m4v|svi|3gp|3g2|mxf|roq|nsv)$', 'i');

// ============================================================ //

var SelectionHelper = function() {

    this.selection = {};
}

SelectionHelper.prototype.items = function() {

    var res = [];

    for (var i in this.selection) {

        res.push(this.selection[i]);
    }

    return res;
}

SelectionHelper.prototype.count = function() {

    var res = 0;

    for (var i in this.selection) {

        res++;
    }

    return res;
}

SelectionHelper.prototype.clear = function() {

    this.selection = {};
}

SelectionHelper.prototype.toggle = function(key, val) {

    if (this.selection[key]) {

        delete this.selection[key];
    }
    else {

        this.selection[key] = val || true;
    }
}

SelectionHelper.prototype.contains = function(key) {

    return key in this.selection;
}

SelectionHelper.prototype.keys = function() {

    var res = [];

    for (var i in this.selection) {

        res.push(i);
    }

    return res;
}

// ============================================================ //

var BreadcrumbsHelper = function() {

    this.index = -1;

    this.items = [];
}

BreadcrumbsHelper.prototype.count = function() {

    return this.items.length;
}

BreadcrumbsHelper.prototype.clear = function() {

    this.index = -1;

    this.items = [];
}

BreadcrumbsHelper.prototype.goto = function(index) {

    if (index >= 0 && index < this.items.length) {

        this.index = index;

        this.items.splice(index + 1, this.items.length - index - 1);

        return this.items[index];
    }
}

BreadcrumbsHelper.prototype.back = function() {

    if (this.index > 0) {

        return this.goto(--this.index);
    }
}

BreadcrumbsHelper.prototype.push = function(item) {

    if (this.index < this.items.length - 1) {

        this.items.splice(this.index + 1, this.items.length - this.index - 1);
    }

    this.items.push(item);

    this.index = this.items.length - 1;

    return item;
}

// ============================================================ //

var ObjHelper = {

    clone: function(obj) {

        var res;

        if (typeof obj === "object") {

            if (obj instanceof Array) {

                res = [];

                for (var i in obj) {

                    res.push(ObjHelper.clone(obj[i]));
                }
            }
            else {

                res = {};

                for (var i in obj) {

                    res[i] = ObjHelper.clone(obj[i]);
                }
            }
        }
        else {

            return obj;
        }

        return res;
    }
};

// ============================================================ //
