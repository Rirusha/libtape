/* Copyright 2023-2024 Rirusha
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-only
 */

using Gee;

public class Tape.YaMAPI.Cover : YaMObject {

    public ArrayList<string> uris {
        owned get {
            if (uri != null) {
                return new ArrayList<string>.wrap ({ uri });
            } else {
                return items_uri;
            }
        }
    }

    public string? type_ { get; set; }

    public ArrayList<string> items_uri { get; set; default = new ArrayList<string> (); }

    public string? uri { get; set; default = null; }

    public string? version { get; set; }

    public bool custom { get; set; }

    public Cover () {
        Object ();
    }

    public Cover.liked () {
        Object (uri: "music.yandex.ru/blocks/playlist-cover/playlist-cover_like.png");
    }

    public Cover.empty () {
        Object (uri: "music.yandex.ru/blocks/playlist-cover/playlist-cover_no_cover0.png");
    }
}
