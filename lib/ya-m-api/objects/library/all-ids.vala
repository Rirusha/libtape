/*
 * Copyright (C) 2024 Vladimir Romanov
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

using Gee;

public class Tape.YaMAPI.Library.AllIds : ApiBase.DataObject {

    public HashMap<string, int> default_library { get; set; default = new HashMap<string, int> (); }

    public HashMap<string, int> artists { get; set; default = new HashMap<string, int> (); }

    public HashMap<string, int> albums { get; set; default = new HashMap<string, int> (); }

    public HashMap<string, int> playlists { get; set; default = new HashMap<string, int> (); }

    public HashMap<string, int> users { get; set; default = new HashMap<string, int> (); }

    public HashMap<string, int> genres { get; set; default = new HashMap<string, int> (); }

    public HashMap<string, int> labels { get; set; default = new HashMap<string, int> (); }

    public HashMap<string, int> library { get; set; default = new HashMap<string, int> (); }
}
