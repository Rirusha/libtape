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

using CassetteClient.YaMAPI;

/**
 * Перечисление нейм кейсов.
 */
public enum CassetteClient.Case {
    SNAKE,
    KEBAB,
    CAMEL
}

public enum CassetteClient.ContentType {
    TRACK,
    PLAYLIST,
    ALBUM,
    IMAGE
}

public enum CassetteClient.CacheingState {
    NONE,
    LOADING,
    TEMP,
    PERM
}

/**
 * Enum with cover sizes. These values are set for
 * optimization purposes and to avoid errors with
 * obtaining images from the api.
 */
namespace CassetteClient.CoverSize {
    public const int SMALL = 75;
    public const int BIG = 400;
}

namespace CassetteClient {

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
    public static string? get_context_description (HasID yam_obj) {
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
         * Error while truing authorize.
         */
        AUTH_ERROR
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
