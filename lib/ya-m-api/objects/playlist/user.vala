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

public class Tape.YaMAPI.User : YaMObject {

    public string uid { get; set; }

    public string? login { get; set; }

    public string name { get; set; }

    public string? display_name { get; set; }

    public string? full_name { get; set; }

    public string? sex { get; set; }

    public bool verified { get; set; }

    public string get_user_name () {
        if (display_name != null) {
            return display_name;
        }

        return name;
    }
}
