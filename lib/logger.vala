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

public sealed class Tape.Logger : Object {

    const string EMPTY_PREFIX = "         ";
    const string SYSTEM_PREFIX = "*SYSTEM* ";
    const string DEBUG_PREFIX = "*DEBUG*  ";
    const string DEVEL_PREFIX = "*DEVEL*  ";
    const string INFO_PREFIX = "*INFO*   ";
    const string WARNING_PREFIX = "*WARNING*";
    const string ERROR_PREFIX = "*ERROR*  ";

    /**
     * Include devel logs.
     * IMPORTANT: devel logs include
     * user authorization token.
     */
    public static bool include_devel { get; set; default = false; }

    static bool _include_debug = false;
    /**
     * Include additional information logs.
     * Doesn't make sense if include_devel is ``true``
     */
    public static bool include_debug {
        get {
            return _include_debug || include_devel;
        }
        set {
            _include_debug = value;
        }
    }

    static File _log_file = null;
    public static File log_file {
        get {
            return _log_file;
        }
        set {
            if (_log_file != null) {
                try {
                    Logger._log_file.delete ();
                } catch (Error e) {}
            }

            if (value.query_exists () && !include_debug) {
                try {
                    value.delete ();
                } catch (Error e) {}
            }

            if (!value.query_exists ()) {
                try {
                    value.create (FileCreateFlags.PRIVATE);

                    Logger._log_file = value;
                    Logger.info ("Log file created");

                } catch (Error e) {
                    GLib.warning ("Can't create log file on %s. Error message: %s".printf (
                        value.peek_path (),
                        e.message
                    ));
                }
            }

            write_to_file (SYSTEM_PREFIX, "\n\nLog initialized\n");
        }
    }

    static string form_log_string (
        string log_prefix,
        string? message
    ) {
        return "%s : %s : %s\n".printf (
            log_prefix,
            new DateTime.now ().format ("%T.%f"),
            message
        );
    }

    static void write_to_file (
        string log_prefix,
        string? message
    ) {
        if (log_file == null) {
            return;
        }

        try {
            FileOutputStream os = log_file.append_to (FileCreateFlags.NONE);

            string final_message;
            if (message != null) {
                final_message = form_log_string (log_prefix, message);
            } else {
                final_message = "\n";
            }

            os.write (final_message.data);

        } catch (Error e) {
            GLib.warning ("Can't write to log file. Error message: %s".printf (e.message));
        }
    }

    public static void empty () {
        write_to_file (EMPTY_PREFIX, null);
    }

    public static void net (
        char direction,
        string data
    ) {
        if (include_devel) {
            write_to_file (direction.to_string (), data);
        }
    }

    public static void debug (string message) {
        if (include_debug) {
            write_to_file (DEBUG_PREFIX, message);
            GLib.debug (message);
        }
    }

    public static void devel (string message) {
        if (include_devel) {
            write_to_file (DEVEL_PREFIX, message);
            stdout.printf (form_log_string (DEVEL_PREFIX, message));
        }
    }

    public static void info (string message) {
        write_to_file (INFO_PREFIX, message);
        GLib.info (message);
    }

    public static void warning (string message) {
        write_to_file (WARNING_PREFIX, message);
        GLib.warning (message);
    }

    public static void error (string message) {
        write_to_file (ERROR_PREFIX, message);
        GLib.error (message);
    }
}
