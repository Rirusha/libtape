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

public class Tape.YaMAPI.TrackHeap : YaMObject, HasID, HasTracks {

    public string oid {
        owned get {
            return "";
        }
    }

    public ArrayList<Track> tracks { get; set; default = new ArrayList<Track> (); }

    public Gee.ArrayList<YaMAPI.Track> get_filtered_track_list (bool with_explicit,
                                                                bool with_child,
                                                                string[] exception_tracks_ids = new string[0]) {
        var out_track_list = new ArrayList<Track> ();

        foreach (Track track in tracks) {
            if (
                (track.available && (
                                     (!track.is_explicit || with_explicit) &&
                                     (!track.is_suitable_for_children || with_child)
                 )) || track.id in exception_tracks_ids
            ) {
                out_track_list.add (track);
            }
        }

        return out_track_list;
    }
}
