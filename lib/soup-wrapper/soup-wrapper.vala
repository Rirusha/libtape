/*
 * Copyright (C) 2023-2024 Rirusha
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

public sealed class Tape.SoupWrapper : Object {

    Gee.HashMap<string, Headers> presets_table = new Gee.HashMap<string, Headers> ();

    Soup.Session session = new Soup.Session () {
        timeout = TIMEOUT
    };

    public string? user_agent {
        construct {
            if (value != null) {
                session.user_agent = value;
            }
        }
    }

    string? _cookies_file_path;
    public string? cookies_file_path {
        private get {
            return _cookies_file_path;
        }
        construct {
            _cookies_file_path = value;

            reload_cookies ();
        }
    }

    public SoupWrapper (string? user_agent = null, string? cookies_file_path = null) {
        Object (
            user_agent: user_agent,
            cookies_file_path: cookies_file_path
        );
    }

    construct {
        if (Logger.include_devel) {
            var logger = new Soup.Logger (Soup.LoggerLogLevel.BODY);

            logger.set_printer ((logger, level, direction, data) => {
                switch (direction) {
                    case '<':
                        Logger.net_in (level, data);
                        break;

                    case '>':
                        Logger.net_out (level, data);
                        break;

                    default:
                        Logger.time ();
                        break;
                }
            });

            session.add_feature (logger);
        }
    }

    public void reload_cookies () {
        if (session.has_feature (typeof (Soup.CookieJarDB))) {
            session.remove_feature_by_type (typeof (Soup.CookieJarDB));
        }

        if (cookies_file_path != null) {
            var cookie_jar = new Soup.CookieJarDB (cookies_file_path, false);
            session.add_feature (cookie_jar);

            Logger.debug (_("Cookies updated. New cookies file: '%s'").printf (cookies_file_path));
        }
    }

    public void add_headers_preset (string preset_name, Header[] headers_arr) {
        var headers = new Headers ();
        headers.set_headers (headers_arr);
        presets_table.set (preset_name, headers);
    }

    void append_headers_with_preset_to (Soup.Message msg, string preset_name) {
        Headers? headers = presets_table.get (preset_name);
        if (headers != null) {
            append_headers_to (msg, headers.get_headers ());
        }
    }

    void append_headers_to (Soup.Message msg, Header[] headers_arr) {
        foreach (Header header in headers_arr) {
            msg.request_headers.append (header.name, header.value);
        }
    }

    void add_params_to_uri (string[,]? parameters, ref string uri) {
        string[] parameters_pairs = new string[parameters.length[0]];

        for (int i = 0; i < parameters.length[0]; i++) {
            parameters_pairs[i] = parameters[i, 0] + "=" + Uri.escape_string (parameters[i, 1]);
        }

        uri += "?" + string.joinv ("&", parameters_pairs);
    }

    Soup.Message message_get (
        owned string uri,
        string[]? header_preset_names = null,
        string[,]? parameters = null,
        Header[]? headers = null
    ) {
        if (parameters != null) {
            add_params_to_uri (parameters, ref uri);
        }

        var msg = new Soup.Message ("GET", uri);

        if (header_preset_names != null) {
            foreach (string preset_name in header_preset_names) {
                append_headers_with_preset_to (msg, preset_name);
            }
        }
        if (headers != null) {
            append_headers_to (msg, headers);
        }

        return msg;
    }

    Soup.Message message_post (
        owned string uri,
        string[]? header_preset_names = null,
        PostContent? post_content = null,
        string[,]? parameters = null,
        Header[]? headers = null
    ) {
        if (parameters != null) {
            add_params_to_uri (parameters, ref uri);
        }

        var msg = new Soup.Message ("POST", uri);

        if (post_content != null) {
            msg.set_request_body_from_bytes (
                post_content.get_content_type_string (),
                post_content.get_bytes ()
            );
        }

        if (header_preset_names != null) {
            foreach (string preset_name in header_preset_names) {
                append_headers_with_preset_to (msg, preset_name);
            }
        }

        if (headers != null) {
            append_headers_to (msg, headers);
        }

        return msg;
    }

    void check_status_code (Soup.Message msg, Bytes bytes) throws ClientError, BadStatusCodeError {
        if (msg.status_code == Soup.Status.OK) {
            return;
        }

        YaMAPI.ApiError error = new YaMAPI.ApiError ();

        try {
            var jsoner = Jsoner.from_bytes (bytes, { "error" }, Case.CAMEL);
            if (jsoner.root.get_node_type () == Json.NodeType.OBJECT) {
                error = (YaMAPI.ApiError) jsoner.deserialize_object (typeof (YaMAPI.ApiError));

            } else {
                jsoner = Jsoner.from_bytes (bytes, null, Case.SNAKE);
                error = (YaMAPI.ApiError) jsoner.deserialize_object (typeof (YaMAPI.ApiError));
            }
        } catch (ClientError e) {}

        error.status_code = msg.status_code;

        switch (msg.status_code) {
            case Soup.Status.BAD_REQUEST:
                throw new BadStatusCodeError.BAD_REQUEST (error.msg);

            case Soup.Status.NOT_FOUND:
                throw new BadStatusCodeError.NOT_FOUND (error.msg);

            case Soup.Status.FORBIDDEN:
                throw new BadStatusCodeError.UNAUTHORIZE_ERROR (error.msg);

            default:
                throw new BadStatusCodeError.UNKNOWN (msg.status_code.to_string () + ": " + error.msg);
        }
    }

    async GLib.Bytes run_async (
        Soup.Message msg,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        GLib.Bytes bytes = null;

        try {
            bytes = yield session.send_and_read_async (msg, priority, cancellable);

        } catch (Error e) {
            throw new ClientError.SOUP_ERROR ("%s %s: %s".printf (msg.method, msg.uri.to_string (), e.message));
        }

        check_status_code (msg, bytes);

        return bytes;
    }

    public async GLib.Bytes get_async (
        owned string uri,
        string[]? header_preset_names = null,
        string[,]? parameters = null,
        Header[]? headers = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        var msg = message_get (
            uri,
            header_preset_names,
            parameters,
            headers
        );

        return yield run_async (msg, priority, cancellable);
    }

    public async GLib.Bytes post_async (
        owned string uri,
        string[]? header_preset_names = null,
        PostContent? post_content = null,
        string[,]? parameters = null,
        Header[]? headers = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        var msg = message_post (
            uri,
            header_preset_names,
            post_content,
            parameters,
            headers
        );

        return yield run_async (msg, priority, cancellable);
    }
}
