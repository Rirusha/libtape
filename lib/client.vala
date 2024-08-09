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

/**
 * IMPORTANT: Client settings should be bound or set before init
 */
public class CassetteClient.Client: Object {

    public static CassetteClient.Settings settings { get; default = new CassetteClient.Settings (); }

    /**
     * Cachier module.
     */
    public static Cachier cachier { get; private set; }

    /**
     * YaMTalker module.
     */
    public static YaMTalker ya_m_talker { get; private set; }

    /**
     * Player module.
     */
    public static Player player { get; private set; }

    public static void init () {
        Threader.init (settings.max_thread_number);

        cachier = new Cachier ();
        ya_m_talker = new YaMTalker ();
        player = new Player ();

        Mpris.init ();
    }
}
