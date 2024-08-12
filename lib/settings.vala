/*
 * Copyright 2024 Rirusha
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

[SingleInstance]
public sealed class Tape.Settings : Object {

    /**
     * Player's repeat mode. Should be used instead of `player.repat_mode`.
     */
    public RepeatMode repeat_mode { get; set; default = RepeatMode.OFF; }

    /**
     * Player's shuffle mode. Should be used instead of `player.shuffle_mode`.
     */
    public ShuffleMode shuffle_mode { get; set; default = ShuffleMode.OFF; }

    /**
     * Player's volume. Should be used instead of `player.volume`.
     */
    public double volume { get; set; default = 0.2; }

    /**
     * Player's mute. Should be used instead of `player.mute`.
     */
    public bool mute { get; set; default = false; }

    /**
     * Max thread amount of each threader worker. Need restart to apply.
     */
    public int max_thread_number { get; construct; }

    /**
     * If `true` tracks are added to the beginning of the playlist,
     * otherwise to the end.
     */
    public bool add_tracks_to_start { get; set; default = true; }

    /**
     * Download hight quality tracks or not.
     */
    public bool is_hq { get; set; default = true; }

    /**
     * Save content on disk or not.
     */
    public bool can_cache { get; set; default = true; }
}
