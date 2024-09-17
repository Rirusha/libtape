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

using Tape.YaMAPI;

namespace Tape {

    public delegate void NetFunc () throws ClientError, BadStatusCodeError;

    /**
     * Timeout for all requests.
     */
    public const int TIMEOUT = 10;

    /**
     * Client errors.
     */
    public errordomain ClientError {

        /**
         * Error while parsing json.
         */
        PARSE_ERROR,

        /**
         * Error while trying send request.
         */
        SOUP_ERROR,

        /**
         * Error while geting error from api.
         */
        ANSWER_ERROR,

        /**
         * Error while trying authorize.
         */
        AUTH_ERROR
    }

    public errordomain BadStatusCodeError {

        BAD_REQUEST = 400,

        NOT_FOUND = 404,

        UNAUTHORIZE_ERROR = 403,

        UNKNOWN = 0
    }

    /**
     * Errors containing reasons why using the client is not possible
     */
    public errordomain CantUseError {

        /**
         * User hasn't Plus Subscription
         */
        NO_PLUS
    }

    namespace Filenames {
        public const string ROOT_DIR_NAME = Config.APP_NAME_LOWER;
        public const string COOKIES = Config.APP_NAME_LOWER + ".cookies";
        public const string LOG = Config.APP_NAME_LOWER + ".log";
        public const string DATABASE = Config.APP_NAME_LOWER + ".db";
        public const string IMAGES = "images";
        public const string AUDIOS = "audios";
        public const string OBJECTS = "objs";
    }

    /**
     * Enum with cover sizes. These values are set for
     * optimization purposes and to avoid errors with
     * obtaining images from the api.
     */
    namespace CoverSize {
        public const int SMALL = 75;
        public const int BIG = 400;
    }

    public enum PlayerState {
        NONE,
        PLAYING,
        PAUSED
    }

    public enum RepeatMode {
        OFF,
        ONE,
        QUEUE
    }

    public enum ShuffleMode {
        OFF,
        ON
    }

    public enum PostContentType {
        X_WWW_FORM_URLENCODED,
        JSON
    }

    /**
     * Перечисление нейм кейсов.
     */
    public enum Case {
        SNAKE,
        KEBAB,
        CAMEL
    }

    public enum ContentType {
        TRACK,
        PLAYLIST,
        ALBUM,
        IMAGE
    }

    public enum CacheingState {
        NONE,
        LOADING,
        TEMP,
        PERM
    }

    public async void wait_async (uint seconds) {
        Timeout.add_seconds_once (seconds, () => {
            Idle.add (wait_async.callback);
        });

        yield;
    }

    public static void check_client_initted () {
        if (Client.player == null ||
            Client.cachier == null ||
            Client.ya_m_talker == null
        ) {
            Logger.error (_("Client not initted"));
        }
    }

    /**
     * Переключить режим перемешивания на следующий.
     * ON -> OFF
     * OFF -> ON
     */
    public static void roll_shuffle_mode () {
        check_client_initted ();

        switch (Client.player.shuffle_mode) {
        case ShuffleMode.OFF:
            Client.player.shuffle_mode = ShuffleMode.ON;
            break;

        case ShuffleMode.ON:
            Client.player.shuffle_mode = ShuffleMode.OFF;
            break;
        }
    }

    /**
     * Переключить режим повтора на следующий.
     * OFF -> REPEAT_ALL
     * REPEAT_ALL -> REPEAT_ONE
     * REPEAT_ONE -> OFF
     */
    public static void roll_repeat_mode () {
        check_client_initted ();

        switch (Client.player.repeat_mode) {
        case RepeatMode.OFF:
            if (Client.player.mode is PlayerFlow) {
                Client.player.repeat_mode = RepeatMode.ONE;
            } else {
                Client.player.repeat_mode = RepeatMode.QUEUE;
            }
            break;

        case RepeatMode.QUEUE:
            Client.player.repeat_mode = RepeatMode.ONE;
            break;

        case RepeatMode.ONE:
            Client.player.repeat_mode = RepeatMode.OFF;
            break;
        }
    }

    public string get_share_link (YaMAPI.YaMObject yam_obj) {
        if (yam_obj is YaMAPI.Track) {
            var track_info = (YaMAPI.Track) yam_obj;

            if (track_info.albums.size == 0) {
                Logger.warning (_("User owned tracks can't be shared"));
                return "";
            } else {
                return "https://music.yandex.ru/album/%s/track/%s?utm_medium=copy_link".printf (
                                                                                                track_info.albums[0].id, track_info.id
                );
            }
        } else if (yam_obj is YaMAPI.Playlist) {
            var playlist_info = (YaMAPI.Playlist) yam_obj;

            return "https://music.yandex.ru/users/%s/playlists/%s?utm_medium=copy_link".printf (
                                                                                                playlist_info.owner.login, playlist_info.kind
            );
        } else if (yam_obj is YaMAPI.Album) {
            var album_info = (YaMAPI.Album) yam_obj;

            return "https://music.yandex.ru/albums/%s?utm_medium=copy_link".printf (
                                                                                    album_info.oid
            );
        } else if (yam_obj is YaMAPI.Artist) {
            var artist_info = (YaMAPI.Artist) yam_obj;

            return "https://music.yandex.ru/artist/%s?utm_medium=copy_link".printf (
                                                                                    artist_info.oid
            );
        } else {
            Logger.error (_("Can't share '%s' object").printf (
                                                               yam_obj.get_type ().name ()
            ));
        }
    }

    // 253.3M -> 253.3 Megabytes
    HumanitySize to_human (string input) {
        string size = input[0 : input.length - 1];
        string unit;

        ulong size_long = (ulong) double.parse (size);

        switch (input[input.length - 1]) {
        case 'B':
            unit = ngettext ("Byte", "Bytes", size_long);
            break;

        case 'K':
            unit = ngettext ("Kilobyte", "Kilobytes", size_long);
            break;

        case 'M':
            unit = ngettext ("Megabyte", "Megabytes", size_long);
            break;

        case 'G':
            unit = ngettext ("Gigabyte", "Gigabytes", size_long);
            break;

        case 'T':
            unit = ngettext ("Terabyte", "Terabytes", size_long);
            break;

        default:
            assert_not_reached ();
        }

        return { size, unit };
    }

    /**
     * Getting the language code to send in api requests.
     * Gets the language from the system and makes a
     * "ru_RU.UTF-8" -> "ru" thing.
     *
     * @return  language code
     */
    public static string get_language () {
        string? locale = Environment.get_variable ("LANG");

        if (locale == null) {
            return "en";
        }

        if ("." in locale) {
            locale = locale.split (".")[0];
        } else if ("@" in locale) {
            locale = locale.split ("@")[0];
        }

        if ("_" in locale) {
            locale = locale.split ("_")[0];
        }

        locale = locale.down ();

        if (locale == "c") {
            return "en";
        }

        return locale;
    }

    /**
     * Milliseconds to seconds.
     *
     * @param ms    milliseconds
     *
     * @return      seconds
     */
    public static int ms2sec (int64 ms) {
        return (int) (ms / 1000);
    }

    /**
     * Get api context type by object.
     *
     * @param yam_obj   object with id
     */
    public static string get_context_type (HasID yam_obj) {
        if (yam_obj is Playlist) {
            return "playlist";
        } else if (yam_obj is Album) {
            return "album";
        } else if (yam_obj is Artist) {
            return "artist";
        } else if (yam_obj is int) {
            return "search";
        } else {
            return "various";
        }
    }

    /**
     * Get api context description by object.
     *
     * @param yam_obj   object with id
     */
    public static string ? get_context_description (HasID yam_obj) {
        if (yam_obj is Playlist) {
            return ((Playlist) yam_obj).title;
        } else if (yam_obj is Album) {
            return ((Album) yam_obj).title;
        } else if (yam_obj is Artist) {
            return ((Artist) yam_obj).name;
        } else {
            return null;
        }
    }

    /**
     * Get current timestamp.
     */
    public static string get_timestamp () {
        return new DateTime.now_utc ().format_iso8601 ();
    }

    /**
     * Utils for generic types.
     */
    public class TypeUtils<T> {

        /**
         * Shuffle list.
         *
         * @param list   `Gee.ArrayList' need to shuffle
         */
        public void shuffle (ref Gee.ArrayList<T> list) {
            for (int i = 0; i < list.size; i++) {
                int random_index = Random.int_range (0, list.size);
                T a = list[i];
                list[i] = list[random_index];
                list[random_index] = a;
            }
        }
    }

    /**
     * Delete `ch` from start and end of `str`
     */
    public string strip (string str, char ch) {
        int start = 0;
        int end = str.length;

        while (str[start] == ch) {
            start++;
        }

        while (str[end - 1] == ch) {
            end--;
        }

        return str[start:end];
    }

    /**
     * Camel string to kebab string.
     *
     * @param camel_string  correct camel string
     */
    public string camel2kebab (string camel_string) {
        var builder = new StringBuilder ();

        int i = 0;
        while (i < camel_string.length) {
            if (camel_string[i].isupper ()) {
                builder.append_c ('-');
                builder.append_c (camel_string[i].tolower ());
            } else {
                builder.append_c (camel_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }

    /**
     * Kebab string to camel string.
     *
     * @param kebab_string  correct kebab string
     */
    public string kebab2camel (string kebab_string) {
        var builder = new StringBuilder ();

        int i = 0;
        while (i < kebab_string.length) {
            if (kebab_string[i] == '-') {
                i += 1;
                builder.append_c (kebab_string[i].toupper ());
            } else {
                builder.append_c (kebab_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }

    /**
     * Kebab string to snake string.
     *
     * @param kebab_string  correct kebab string
     */
    public string kebab2snake (string kebab_string) {
        var builder = new StringBuilder ();

        int i = 0;
        while (i < kebab_string.length) {
            if (kebab_string[i] == '-') {
                builder.append_c ('_');
            } else {
                builder.append_c (kebab_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }

    /**
     * Snake string to kebab string.
     *
     * @param snake_string  correct snake string
     */
    public string snake2kebab (string snake_string) {
        var builder = new StringBuilder ();

        int i = 0;
        while (i < snake_string.length) {
            if (snake_string[i] == '_') {
                builder.append_c ('-');
            } else {
                builder.append_c (snake_string[i]);
            }
            i += 1;
        }

        return builder.free_and_steal ();
    }
}
