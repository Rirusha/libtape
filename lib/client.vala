/*
 * Copyright 2024 Vladimir Romanov
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
    internal static Client root;
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
    public YaMHelper yam_helper { get; private set; }

    /**
     * Player module.
     */
    public Player player { get; private set; }

    public signal void quit ();

    public signal void raise ();

    public signal void mpris_uri_open (string uri);

    public bool network_available { get; private set; }

    NetworkMonitor monitor = NetworkMonitor.get_default ();

    public Client (Tape.Settings settings) {
        Object (settings: settings);
    }

    construct {
        root = this;

        cachier = new Cachier ();
        monitor.network_changed.connect ((is_available) => {
            network_available = is_available;
        });
    }

    public async bool init (string? yam_token = null) throws CantUseError, ApiBase.BadStatusCodeError, ApiBase.SoupError {
        var ser_settings = Serialize.get_settings ();
        ser_settings.names_case = Serialize.Case.CAMEL;

        string? token = yam_token;
        string? cookies_path = null;

        if (token == null) {
            if (cachier.storager.cookies_file.query_exists ()) {
                cookies_path = cachier.storager.cookies_file.peek_path ();
            } else {
                token = cachier.storager.load_token ();
            }
        }

        if (token == null && cookies_path == null) {
            return false;
        }

        yam_helper = new YaMHelper (
            cookies_path,
            token
        );

        player = new Player ();

        try {
            yield yam_helper.init ();
        } catch (Serialize.JsonError e) {
            error (e.message);
        } catch (ApiBase.BadStatusCodeError e) {
            if (e is ApiBase.BadStatusCodeError.UNAUTHORIZED) {
                return false;
            } else {
                if (yam_helper.can_be_offline ()) {
                    return true;
                }
                throw e;
            }
        } catch (ApiBase.SoupError e) {
            if (yam_helper.can_be_offline ()) {
                return true;
            }
            throw e;
        }

        Mpris.init (this);

        if (yam_helper.client.auth_type == TOKEN) {
            cachier.storager.save_token (yam_helper.client.token);
        }

        return true;
    }

    public async void logout () {
        yield cachier.white_list ();
        quit ();
    }
}
