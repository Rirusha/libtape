/*
 * Copyright 2024 Vladimir Vaskov
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
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-only
 */

/**
 * Interface for object that contain tracks.
 */
public interface YaMAPI.HasTracks : ApiBase.DataObject, HasID {

    /**
     * Get a track list filtered by the parameters passed.
     * The feature also does not include unavailable tracks in the list.
     *
     * @param with_explicit         include in result explicit tracks
     * @param with_child            include in result tracks for children
     * @param exception_tracks_ids  except this tracks
     *
     * @return                      filtered track list
     */
    public abstract Gee.ArrayList<YaMAPI.Track> get_filtered_track_list (
        bool with_explicit,
        bool with_child,
        string[] exception_tracks_ids = new string[0]
    );
}
