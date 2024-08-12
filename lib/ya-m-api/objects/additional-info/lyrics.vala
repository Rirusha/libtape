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

public class Tape.YaMAPI.Lyrics : YaMObject {

    public string download_url { get; set; }

    public int lyric_id { get; set; }

    public string? external_lyric_id { get; set; }

    public ArrayList<string> writers { get; set; default = new ArrayList<string> (); }

    public LyricsMajor? major { get; set; }

    public ArrayList<string> text { get; set; default = new ArrayList<string> (); }

    public bool is_sync { get; set; }

    public string get_writers_names () {
        return string.joinv (", ", writers.to_array ());
    }
}
