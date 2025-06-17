/*
 * Copyright 2024 Vladimir Vaskov
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 * 
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public enum YaMAPI.PlaylistVisible {

    PUBLIC,
    PRIVATE;

    public static PlaylistVisible parse (string str) {
        switch (str) {
            case "public":
                return PlaylistVisible.PUBLIC;

            case "private":
                return PlaylistVisible.PRIVATE;

            default:
                assert_not_reached ();
        }
    }

    public string to_string () {
        switch (this) {
            case PUBLIC:
                return "public";

            case PRIVATE:
                return "private";

            default:
                assert_not_reached ();
        }
    }
}
