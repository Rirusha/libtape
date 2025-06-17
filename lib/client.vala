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

namespace Tape {
    public static Client root;
}

[SingleInstance]
public class Tape.Client : Object {

    public Tape.Settings settings { get; construct; }

    /**
     * Cachier module.
     */
    public Cachier cachier { get; private set; }

    /**
     * YaMTalker module.
     */
    public YaMTalker yam_talker { get; private set; }

    /**
     * Player module.
     */
    public Player player { get; private set; }

    public signal void quit ();

    public signal void raise ();

    public signal void mpris_uri_open (string uri);

    public Client (Tape.Settings settings) {
        Object (settings: settings);
    }

    construct {
        cachier = new Cachier ();
        yam_talker = new YaMTalker ();
        player = new Player ();

        Mpris.init (this);
    }
}
