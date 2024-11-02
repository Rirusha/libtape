/*
 * Copyright (C) 2024 Vladimir Vaskov
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

namespace Tape.Mpris {

static Player player;
public static Mpris mpris;
static MprisPlayer mpris_player;

public static void init (Player player) {
    mpris = new Mpris ();
    Tape.Mpris.player = player;

    Bus.own_name (
        BusType.SESSION,
        "org.mpris.MediaPlayer2.%s".printf (Config.APP_ID),
        BusNameOwnerFlags.ALLOW_REPLACEMENT,
        on_bus_aquired
    );
}

static void on_bus_aquired (
    DBusConnection con,
    string name
) {
    try {
        con.register_object ("/org/mpris/MediaPlayer2", mpris);
        var mpris_player = new MprisPlayer (con);
        con.register_object ("/org/mpris/MediaPlayer2", mpris_player);

    } catch (IOError e) {
        Logger.warning ("Error message: %s".printf (e.message));
    }
}

[DBus (name = "org.mpris.MediaPlayer2")]
public class Mpris : Object {
    public bool can_quit { get; set; default = true; }
    public bool can_raise { get; set; default = true; }
    public string desktop_entry { get; set; default = Config.APP_ID; }
    public string identity { get; set; default = Config.APP_NAME; }

    public signal void quit_triggered ();
    public signal void raise_triggered ();

    public void quit (BusName sender) throws Error {
        quit_triggered ();
    }

    public void raise (BusName sender) throws Error {
        raise_triggered ();
    }
}

[DBus (name = "org.mpris.MediaPlayer2.Player")]
public class MprisPlayer : Object {

    DBusConnection con;

    public bool can_control {
        get {
            return true;
        }
    }

    public bool can_go_next {
        get {
            return player.can_go_next;
        }
    }

    public bool can_go_previous {
        get {
            return player.can_go_prev;
        }
    }

    public bool can_pause {
        get {
            return player.can_pause;
        }
    }

    public bool can_seek {
        get {
            return player.can_seek;
        }
    }

    public bool can_play {
        get {
            return player.can_play;
        }
    }

    public string playback_status {
        get {
            switch (player.state) {
                case PlayerState.PLAYING:
                    return "Playing";

                case PlayerState.PAUSED:
                    return "Paused";

                case PlayerState.NONE:
                    return "Stopped";

                default:
                    assert_not_reached ();
            }
        }
    }

    public int64 position {
        get {
            return player.position;
        }
    }

    public double volume {
        get {
            return player.volume;
        }
        set {
            player.volume = value;
        }
    }

    public bool shuffle {
        get {
            return player.shuffle_mode == ShuffleMode.ON;
        }
        set {
            if (value) {
                player.shuffle_mode = ShuffleMode.ON;

            } else {
                player.shuffle_mode = ShuffleMode.OFF;
            }
        }
    }

    public string loop_status {
        get {
            switch (player.repeat_mode) {
                case RepeatMode.OFF:
                    return "None";

                case RepeatMode.ONE:
                    return "Track";

                case RepeatMode.QUEUE:
                    return "Playlist";

                default:
                    assert_not_reached ();
            }
        }
        set {
            switch (value) {
                case "None":
                    player.repeat_mode = RepeatMode.OFF;
                    break;

                case "Track":
                    player.repeat_mode = RepeatMode.ONE;
                    break;

                case "Playlist":
                    player.repeat_mode = RepeatMode.QUEUE;
                    break;
            }
        }
    }

    public signal void seeked (int64 position);

    public HashTable<string, Variant>? metadata {
        owned get {
            return _get_metadata (player.mode.get_current_track_info ());
        }
    }

    public MprisPlayer (DBusConnection con) {
        this.con = con;

        player.played.connect ((track_info) => {
            send_property_change ("Metadata", _get_metadata (track_info));
        });
        player.stopped.connect (() => {
            send_property_change ("Metadata", _get_metadata (null));
        });

        player.notify["volume"].connect (() => {
            send_property_change ("Volume", volume);
        });

        player.notify["shuffle-mode"].connect (() => {
            send_property_change ("Shuffle", shuffle);
        });

        player.notify["repeat-mode"].connect (() => {
            send_property_change ("LoopStatus", loop_status);
        });

        player.notify["state"].connect (() => {
            send_property_change ("PlaybackStatus", playback_status);
        });

        player.notify["can-go-prev"].connect (() => {
            send_property_change ("CanGoPrevious", can_go_previous);
        });

        player.notify["can-go-next"].connect (() => {
            send_property_change ("CanGoNext", can_go_next);
        });

        player.notify["can-play"].connect (() => {
            send_property_change ("CanPlay", can_play);
        });

        player.notify["can-pause"].connect (() => {
            send_property_change ("CanPause", can_pause);
        });

        player.notify["can-seek"].connect (() => {
            send_property_change ("CanSeek", can_seek);
        });

        player.notify["position"].connect (() => {
            send_property_change ("Position", position);
        });

        player.bind_property (
            "volume",
            this, "volume",
            BindingFlags.BIDIRECTIONAL | BindingFlags.SYNC_CREATE
        );

        player.playback_callback.connect ((position) => {
            seeked ((int64) position);
        });
    }

    HashTable<string, Variant> _get_metadata (YaMAPI.Track? track_info) {
        HashTable<string, Variant> metadata = new HashTable<string, Variant> (null, null);

        if (track_info == null) {
            metadata.insert ("mpris:trackid", new ObjectPath ("/io/github/Rirusha/Cassette/Track/0"));

        } else {
            ObjectPath obj_path;
            if (track_info.is_ugc) {
                obj_path = new ObjectPath (@"/io/github/Rirusha/Cassette/Track/$(track_info.id.hash ())");

            } else {
                obj_path = new ObjectPath (@"/io/github/Rirusha/Cassette/Track/$(track_info.id)");
            }

            string[] artists = new string[track_info.artists.size];
            for (int i = 0; i < artists.length; i++) {
                artists[i] = track_info.artists[i].name;
            }

            var cover_items = track_info.get_cover_items_by_size ((int) CoverSize.BIG);

            string cover_uri = "";
            if (cover_items.size != 0) {
                cover_uri = cover_items[0];
            }

            metadata.insert ("mpris:trackid", obj_path);
            metadata.insert ("mpris:length", new Variant ("i", track_info.duration_ms * 1000));
            metadata.insert ("mpris:artUrl", cover_uri);
            metadata.insert ("xesam:title", track_info.title);
            metadata.insert ("xesam:album", track_info.get_album_title ());
            metadata.insert ("xesam:albumArtist", artists);
            metadata.insert ("xesam:artist", artists);
        }

        return metadata;
    }

    // Tnanks https://github.com/bcedu/MuseIC
    bool send_property_change (
        string property,
        Variant variant
    ) {
        var builder = new VariantBuilder (VariantType.ARRAY);
        var invalidated_builder = new VariantBuilder (new VariantType ("as"));
        builder.add ("{sv}", property, variant);

        try {
            con.emit_signal (
                null,
                "/org/mpris/MediaPlayer2",
                "org.freedesktop.DBus.Properties",
                "PropertiesChanged",
                new Variant (
                    "(sa{sv}as)",
                    "org.mpris.MediaPlayer2.Player",
                    builder,
                    invalidated_builder
                )
            );

        } catch (Error e) {
            Logger.warning ("Could not send MPRIS property change: %s".printf (e.message));
        }

        return false;
    }

    public void next (BusName sender) throws Error {
        if (can_go_next) {
            player.next ();
        }
    }

    public void previous (BusName sender) throws Error {
        if (can_go_previous) {
            player.prev ();
        }
    }

    public void play (BusName sender) throws Error {
        if (can_control) {
            player.play ();
        }
    }

    public void pause (BusName sender) throws Error {
        if (can_control) {
            player.pause ();
        }
    }

    public void play_pause (BusName sender) throws Error {
        if (can_control) {
            player.play_pause ();
        }
    }

    public void stop (BusName sender) throws Error {
        if (can_control) {
            player.clear_mode ();
        }
    }

    public void seek (
        int64 offset,
        BusName sender
    ) throws Error {
        if (can_seek) {
            player.seek ((position + offset) / 1000);
        }
    }

    public void set_position (
        ObjectPath track_id,
        int64 position,
        BusName sender
    ) throws Error {
        if (can_seek) {
            player.seek ((position) / 1000);
        }
    }
}
}
