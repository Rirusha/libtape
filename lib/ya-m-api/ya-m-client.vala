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

using Tape.YaMAPI.Rotor;

public sealed class Tape.YaMAPI.YaMClient : Object {

    const string USER_AGENT = "libtape";
    const string YAM_BASE_URL = "https://api.music.yandex.net";

    public SoupWrapper soup_wrapper { private get; construct; }

    public AuthType auth_type { get; construct; }

    public string token { get; set construct; default = ""; }

    public Account.About? me { get; private set; default = null; }

    public bool is_init_complete {
        get {
            return me != null;
        }
    }

    YaMClient () {
        Object ();
    }

    public YaMClient.with_token (string token) {
        Object (
            soup_wrapper: new SoupWrapper (USER_AGENT),
            token: token,
            auth_type: AuthType.TOKEN
        );
    }

    public YaMClient.with_cookie (string cookie_path, CookieJarType cookie_jar_type) {
        AuthType auth_type;
        switch (cookie_jar_type) {
            case DB:
                auth_type = COOKIES_DB;
                break;

            case TEXT:
                auth_type = COOKIES_TEXT;
                break;

            default:
                assert_not_reached ();
        }

        Object (
            soup_wrapper: new SoupWrapper (USER_AGENT, cookie_path, cookie_jar_type),
            auth_type: auth_type
        );
    }

    construct {
        soup_wrapper.add_headers_preset (
            "device",
            {{
                "X-Yandex-Music-Device",
                "os=%s; os_version=%s; manufacturer=%s; model=%s; clid=; device_id=random; uuid=random".printf (
                    Environment.get_os_info (OsInfoKey.NAME),
                    Environment.get_os_info (OsInfoKey.VERSION),
                    "Rirusha",
                    "Yandex Music API"
                )
            }}
        );
    }

    public async void init (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        if (auth_type != TOKEN) {
            var datalist = Datalist<string> ();
            datalist.set_data ("grant_type", "sessionid");
            datalist.set_data ("client_id", "23cabbbdc6cd418abb4b39c32c41195d");
            datalist.set_data ("client_secret", "53bc75238f0c4d08a118e51fe9203300");
            datalist.set_data ("host", "oauth.yandex.ru");

            PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
            post_content.set_datalist (datalist);

            var bytes = yield soup_wrapper.post (
                "https://oauth.yandex.ru/token",
                null,
                post_content,
                null,
                null,
                priority,
                cancellable
            );
            var jsoner = Jsoner.from_bytes (bytes, { "access_token" }, Case.SNAKE);

            var val = jsoner.deserialize_value ();

            if (val.type () == Type.STRING) {
                token = val.get_string ();
            }
        }

        if (token != "") {
            soup_wrapper.add_headers_preset (
                "default",
                {
                    { "Authorization", @"OAuth $token" },
                    { "X-Yandex-Music-Client", "YandexMusicAndroid/24023231" }
                }
            );
            soup_wrapper.add_headers_preset (
                "auth",
                {
                    { "Authorization", @"OAuth $token" }
                }
            );

            me = yield account_about (priority, cancellable);
        } else {
            throw new ClientError.AUTH_ERROR (_("No token provided"));
        }
    }

    /**
     * Получит содержимое по url
     *
     * @param url   url, по котором нужно получить контент
     *
     * @return      контент в байтах
     */
    public async Bytes get_content_of (
        string url,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        return yield soup_wrapper.get (
            url,
            null,
            null,
            null,
            priority,
            cancellable
        );
    }

    /**
     * Проверить uid пользователя на наличие
     */
    void check_uid (ref string? uid) throws ClientError {
        if (uid == null) {
            if (me != null) {
                return;
            }

            uid = me.uid;
            if (uid != null) {
                return;
            }

            throw new ClientError.AUTH_ERROR (_("Authorization not completed"));
        }
    }

    /**
     *
     */
    public async void account_experiments () throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void account_experiments_details () throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void account_settings () throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     * Получение информации о текущем пользователе
     */
    public async Account.About account_about (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        var bytes = yield soup_wrapper.get (
            @"$(YAM_BASE_URL)/account/about",
            { "default" },
            null,
            null,
            priority,
            cancellable
        );

        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return (Account.About) yield jsoner.deserialize_object (typeof (Account.About));
    }

    /**
     *
     */
    public async void albums_with_tracks (
        string album_id,
        bool rich_tracks,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async Playlist playlist (
        string playlist_uuid,
        bool resume_stream,
        bool rich_tracks,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        var bytes = yield soup_wrapper.get (
            @"$(YAM_BASE_URL)/playlist/$playlist_uuid",
            { "default" },
        {
                { "resumeStream", resume_stream.to_string () },
                { "richTracks", rich_tracks.to_string () }
            },
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return (Playlist) yield jsoner.deserialize_object (typeof (Playlist));
    }

    /**
     *
     */
    public async void playlists (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_tracks (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_track_ids (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_safe_direct_albums (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_brief_info (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_similar (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_discography_albums (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_direct_albums (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_also_albums (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void artists_concerts (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void users_playlists_list_kinds (
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);
    }

    /**
     *
     */
    public async void users_playlists (
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);
    }

    /**
     *
     */
    public async Gee.ArrayList<Playlist> users_playlists_list (
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError,
    BadStatusCodeError {
        check_uid (ref uid);

        Bytes bytes = yield soup_wrapper.get (
            @"$(YAM_BASE_URL)/users/$uid/playlists/list",
            { "default" },
            null,
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var playlist_array = new Gee.ArrayList<Playlist> ();
        yield jsoner.deserialize_array (playlist_array);

        return playlist_array;
    }

    /**
     *
     */
    public async Playlist users_playlists_playlist (
        string playlist_kind,
        bool rich_tracks,
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var bytes = yield soup_wrapper.get (
            @"$(YAM_BASE_URL)/users/$uid/playlists/$playlist_kind",
            { "default" },
            {
                { "richTracks", rich_tracks.to_string () }
            },
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return (Playlist) yield jsoner.deserialize_object (typeof (Playlist));
    }

    /**
     *
     */
    public async void users_playlists_playlist_change_relative (
        string playlist_kind,
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);
    }

    public async bool users_playlists_delete (
        owned string? uid,
        string kind,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        Bytes bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/playlists/$kind/delete",
            { "default" },
            null,
            null,
            null,
            priority,
            cancellable
        );

        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);
        if (jsoner.root != null) {
            return true;
        }
        return false;
    }

    public async Playlist users_playlists_change (
        owned string? uid,
        string kind,
        string diff,
        int revision = 1,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var datalist = Datalist<string> ();
        datalist.set_data ("kind", kind);
        datalist.set_data ("revision", revision.to_string ());
        datalist.set_data ("diff", diff);

        PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
        post_content.set_datalist (datalist);

        Bytes bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$(uid)/playlists/$kind/change",
            { "default" },
            post_content,
            null,
            null,
            priority,
            cancellable
        );

        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return (Playlist) yield jsoner.deserialize_object (typeof (Playlist));
    }

    public async Playlist users_playlists_create (
        owned string? uid,
        string title,
        PlaylistVisible visibility = PlaylistVisible.PRIVATE,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var datalist = Datalist<string> ();
        datalist.set_data ("title", title);
        datalist.set_data ("visibility", visibility.to_string ());

        PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
        post_content.set_datalist (datalist);

        Bytes bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/playlists/create",
            { "default" },
            post_content,
            null,
            null,
            priority,
            cancellable
        );

        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return (Playlist) yield jsoner.deserialize_object (typeof (Playlist));
    }

    public async Playlist users_playlists_name (
        owned string? uid,
        string kind,
        string new_name,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var datalist = Datalist<string> ();
        datalist.set_data ("value", new_name);

        PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
        post_content.set_datalist (datalist);

        Bytes bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/playlists/$kind/name",
            { "default" },
            post_content,
            null,
            null,
            priority,
            cancellable
        );

        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return (Playlist) yield jsoner.deserialize_object (typeof (Playlist));
    }

    public async PlaylistRecommendations users_playlists_recommendations (
        owned string? uid,
        string kind,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError,
    BadStatusCodeError {
        check_uid (ref uid);

        var bytes = yield soup_wrapper.get (
            @"$(YAM_BASE_URL)/users/$uid/playlists/$kind/recommendations",
            { "default" },
            null,
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return (PlaylistRecommendations) yield jsoner.deserialize_object (typeof (PlaylistRecommendations));
    }

    public async Playlist users_playlists_visibility (
        owned string? uid,
        string kind,
        string visibility,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var datalist = Datalist<string> ();
        datalist.set_data ("value", visibility);

        PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
        post_content.set_datalist (datalist);

        Bytes bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/playlists/$kind/visibility",
            { "default" },
            post_content,
            null,
            null,
            priority,
            cancellable
        );

        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return (Playlist) yield jsoner.deserialize_object (typeof (Playlist));
    }

    public async Playlist users_palylists_cover_upload (
        owned string? uid,
        string kind,
        uint8[] new_cover,
        string filename,
        string content_type,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var post_builder = new StringBuilder ();

        post_builder.append (Uuid.string_random ());
        post_builder.append_printf ("Content-Disposition: form-data; name=\"image\"; filename=\"%s\"\n", filename);
        post_builder.append_printf ("Content-Type: %s\n", content_type);
        post_builder.append_printf ("Content-Length: %d\n", new_cover.length);
        post_builder.append ("\n");
        post_builder.append ((string) new_cover);

        PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED, post_builder.free_and_steal () };

        Bytes bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/playlists/$kind/cover/upload",
            { "default" },
            post_content,
            null,
            null,
            priority,
            cancellable
        );

        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return (Playlist) yield jsoner.deserialize_object (typeof (Playlist));
    }

    public async Playlist users_palylists_cover_clear (
        owned string? uid,
        string kind,
        uint8[] new_cover,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        Bytes bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/playlists/$kind/cover/clear",
            { "default" },
            null,
            null,
            null,
            priority,
            cancellable
        );

        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return (Playlist) yield jsoner.deserialize_object (typeof (Playlist));
    }

    /**
     *
     */
    public async void users_likes_albums (
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);
    }

    /**
     *
     */
    public async void users_likes_artists (
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);
    }

    /**
     *
     */
    public async Gee.ArrayList<LikedPlaylist> users_likes_playlists (
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        Bytes bytes = yield soup_wrapper.get (
            @"$(YAM_BASE_URL)/users/$uid/likes/playlists",
            { "default" },
            null,
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var playlist_array = new Gee.ArrayList<LikedPlaylist> ();
        yield jsoner.deserialize_array (playlist_array);
        return playlist_array;
    }

    /**
     *
     */
    public async int64 users_likes_tracks_add (
        string track_id,
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/likes/tracks/add",
            { "default" },
            null,
            { { "track-id", track_id } },
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result", "revision" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.INT64) {
            return value.get_int64 ();
        }
        return 0;
    }

    /**
     *
     */
    public async int64 users_likes_tracks_remove (
        string track_id,
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/likes/tracks/$track_id/remove",
            { "default" },
            null,
            null,
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result", "revision" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.INT64) {
            return value.get_int64 ();
        }
        return 0;
    }

    public async Gee.ArrayList<TrackShort> users_dislikes_tracks (
        owned string? uid,
        int if_modified_since_revision = 0,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError,
    BadStatusCodeError {
        check_uid (ref uid);

        var bytes = yield soup_wrapper.get (
            @"$(YAM_BASE_URL)/users/$uid/dislikes/tracks",
            { "default" },
            {
                { "if_modified_since_revision", if_modified_since_revision.to_string () }
            },
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result", "library", "tracks" }, Case.CAMEL);

        var our_array = new Gee.ArrayList<TrackShort> ();
        yield jsoner.deserialize_array (our_array);

        return our_array;
    }

    /**
     *
     */
    public async int64 users_dislikes_tracks_add (
        string track_id,
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/dislikes/tracks/add",
            { "default" },
            null,
            {
                { "track-id", track_id }
            },
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result", "revision" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.INT64) {
            return value.get_int64 ();
        }
        return 0;
    }

    /**
     *
     */
    public async int64 users_dislikes_tracks_remove (
        string track_id,
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/dislikes/tracks/$track_id/remove",
            { "default" },
            null,
            null,
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result", "revision" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.INT64) {
            return value.get_int64 ();
        }
        return 0;
    }

    /**
     *
     */
    public async bool users_likes_artists_add (
        string artist_id,
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/likes/artists/add",
            { "default" },
            null,
            {
                { "artist-id", artist_id }
            },
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.STRING) {
            return value.get_string () == "ok";
        }
        return false;
    }

    /**
     *
     */
    public async bool users_likes_artists_remove (
        string artist_id,
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/likes/artists/$artist_id/remove",
            { "default" },
            null,
            null,
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.STRING) {
            return value.get_string () == "ok";
        }
        return false;
    }

    /**
     *
     */
    public async bool users_dislikes_artists_add (
        string artist_id,
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/dislikes/artists/add",
            { "default" },
            null,
            {
                { "artist-id", artist_id }
            },
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.STRING) {
            return value.get_string () == "ok";
        }
        return false;
    }

    /**
     *
     */
    public async bool users_dislikes_artists_remove (
        string artist_id,
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/dislikes/artists/$artist_id/remove",
            { "default" },
            null,
            null,
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.STRING) {
            return value.get_string () == "ok";
        }
        return false;
    }

    /**
     *
     */
    public async bool users_likes_albums_add (
        string album_id,
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/likes/albums/add",
            { "default" },
            null,
            {
                { "album-id", album_id }
            },
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.STRING) {
            return value.get_string () == "ok";
        }
        return false;
    }

    /**
     *
     */
    public async bool users_likes_albums_remove (
        string album_id,
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/likes/albums/$album_id/remove",
            { "default" },
            null,
            null,
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.STRING) {
            return value.get_string () == "ok";
        }
        return false;
    }

    /**
     *
     */
    public async bool users_likes_playlists_add (
        string playlist_uid,
        string owner_uid,
        string playlist_kind,
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/likes/playlists/add",
            { "default" },
            null,
            {
                { "playlist-uuid", playlist_uid },
                { "owner-uid", owner_uid },
                { "kind", playlist_kind }
            },
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.STRING) {
            return value.get_string () == "ok";
        }
        return false;
    }

    /**
     *
     */
    public async bool users_likes_playlists_remove (
        string playlist_uid,
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);

        var bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/users/$uid/likes/playlists/$playlist_uid/remove",
            { "default" },
            null,
            null,
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var value = jsoner.deserialize_value ();

        if (value.type () == Type.STRING) {
            return value.get_string () == "ok";
        }
        return false;
    }

    /**
     *
     */
    public async void users_presaves_add (
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);
    }

    /**
     *
     */
    public async void users_presaves_remove (
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);
    }

    /**
     *
     */
    public async void users_search_history (
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);
    }

    /**
     *
     */
    public async void users_search_history_clear (
        owned string? uid = null,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        check_uid (ref uid);
    }

    /**
     * Получение данных о библиотеке пользователя
     */
    public async Library.AllIds library_all_ids (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        var bytes = yield soup_wrapper.get (
            @"$(YAM_BASE_URL)/library/all-ids",
            { "default" },
            null,
            null,
            priority,
            cancellable
        );

        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return yield jsoner.deserialize_lib_data ();
    }

    /**
     *
     */
    public async void landing3_metatags (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void metatags_metatag (
        string metatag,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void metatags_albums (
        string metatag,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void metatags_artists (
        string metatag,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void metatags_playlists (
        string metatag,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void top_category (
        string category,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void rotor_station_info (
        string station_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void rotor_station_stream (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async StationTracks rotor_session_new (
        SessionNew session_new,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        PostContent post_content = {
            PostContentType.JSON,
            yield Jsoner.serialize (session_new, Case.CAMEL)
        };

        Bytes bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/rotor/session/new",
            { "default" },
            post_content,
            null,
            null,
            priority,
            cancellable
        );

        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return (StationTracks) yield jsoner.deserialize_object (typeof (StationTracks));
    }

    /**
     *
     */
    public async StationTracks rotor_session_tracks (
        string radio_session_id,
        Rotor.Queue queue,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        PostContent post_content = {
            PostContentType.JSON,
            yield Jsoner.serialize (queue, Case.CAMEL)
        };

        Bytes bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/rotor/session/$radio_session_id/tracks",
            { "default" },
            post_content,
            null,
            null,
            priority,
            cancellable
        );

        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return (StationTracks) yield jsoner.deserialize_object (typeof (StationTracks));
    }

    /**
     *
     */
    public async void rotor_session_feedback (
        string radio_session_id,
        Rotor.Feedback feedback,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        PostContent post_content = {
            PostContentType.JSON,
            yield Jsoner.serialize (feedback, Case.CAMEL)
        };

        yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/rotor/session/$radio_session_id/feedback",
            { "default" },
            post_content,
            null,
            null,
            priority,
            cancellable
        );
    }

    /**
     * Метод для получения всех возможных настроек волны
     *
     * @return  объект `Tape.YaMAPI.Rotor.Settings`, содержащий все настройки
     */
    public async Rotor.Settings rotor_wave_settings (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        var bytes = yield soup_wrapper.get (
            @"$(YAM_BASE_URL)/rotor/wave/settings",
            { "default" },
            {
                { "language", get_language () }
            },
            null,
            priority,
            cancellable
        );

        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return (Rotor.Settings) yield jsoner.deserialize_object (typeof (Rotor.Settings));
    }

    /**
     * Получение последней прослушиваемой волны текущим пользователем
     */
    public async Rotor.Wave rotor_wave_last (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        var bytes = yield soup_wrapper.get (
            @"$(YAM_BASE_URL)/rotor/wave/last",
            { "default" },
            {
                { "language", get_language () }
            },
            null,
            priority,
            cancellable
        );

        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return (Wave) yield jsoner.deserialize_object (typeof (Wave));
    }

    /**
     * Сбросить значение последней прослушиваемой станции.
     *
     * @return  успех выполнения
     */
    public async bool rotor_wave_last_reset (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        var bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/rotor/wave/last/reset",
            { "default" },
            null,
            null,
            null,
            priority,
            cancellable
        );

        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        if (jsoner.root == null) {
            return false;
        }

        return jsoner.deserialize_value ().get_string () == "ok";
    }

    public async Dashboard rotor_stations_dashboard (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        var bytes = yield soup_wrapper.get (
            @"$(YAM_BASE_URL)/rotor/stations/dashboard",
            { "default", "device" },
            {
                { "language", get_language () }
            },
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return (Dashboard) yield jsoner.deserialize_object (typeof (Dashboard));
    }

    public async Gee.ArrayList<Station> rotor_stations_list (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        var bytes = yield soup_wrapper.get (
            @"$(YAM_BASE_URL)/rotor/stations/list",
            { "default", "device" },
            {
                { "language", get_language () }
            },
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var sl_array = new Gee.ArrayList<Station> ();
        yield jsoner.deserialize_array (sl_array);

        return sl_array;
    }

    /**
     *
     */
    public async void search_feedback (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void search_instant_mixed (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     * Метод отправки фидбека о прослушивании трека.
     *
     * @param play_id               id сессии прослушивания
     * @param total_played_seconds  общее количество прослушанного времени в секундах
     * @param end_position_seconds  секунда, на которой закончилось прослушивание
     * @param track_length_seconds  общее количество секунд в треке
     * @param track_id              id трека
     * @param album_id              id вльбома, может быть `null`
     * @param from
     * @param context               контекст воспроизведения (То же что и `Queue.context.type`)
     * @param context_item          id контекста, (Тоже же, что и `Queue.context.id`)
     * @param radio_session_id      id сессии волны
     *
     * @return                      успех выполнения
     */
    public async bool plays (
        Play[] play_objs,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        var plays_obj = new Plays ();
        plays_obj.plays.add_all_array (play_objs);

        PostContent post_content = {
            PostContentType.JSON,
            yield Jsoner.serialize (plays_obj, Case.CAMEL)
        };

        Bytes bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/plays",
            { "default" },
            post_content,
            {
                { "clientNow", get_timestamp () }
            },
            null,
            priority,
            cancellable
        );

        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        if (jsoner.root == null) {
            return false;
        }

        return jsoner.deserialize_value ().get_string () == "ok";
    }

    /**
     *
     */
    public async void rewind_slides_user (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void rewind_slides_artist (
        string artist_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void pins (
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void pins_albums (
        bool pin,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void pins_playlist (
        bool pin,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void pins_artist (
        bool pin,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void pins_wave (
        bool pin,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void tags_playlist_ids (
        string tag_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    /**
     *
     */
    public async void feed_promotions_promo (
        string promo_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        assert_not_reached ();
    }

    public async Gee.ArrayList<Track> tracks (
        string[] id_list,
        bool with_positions = false,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        var datalist = Datalist<string> ();
        datalist.set_data ("track-ids", string.joinv (",", id_list));
        datalist.set_data ("with-positions", with_positions.to_string ());

        PostContent post_content = { PostContentType.X_WWW_FORM_URLENCODED };
        post_content.set_datalist (datalist);

        var bytes = yield soup_wrapper.post (
            @"$(YAM_BASE_URL)/tracks",
            { "default" },
            post_content,
            null,
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var array_list = new Gee.ArrayList<Track> ();
        yield jsoner.deserialize_array (array_list);

        return array_list;
    }

    public async string track_download_url (
        string track_id,
        bool hq = true,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        var di_array = yield tracks_download_info (
            track_id,
            priority,
            cancellable
        );

        int bitrate = hq ? 0 : 500;
        string dl_info_uri = "";
        foreach (DownloadInfo download_info in di_array) {
            if (hq == (bitrate < download_info.bitrate_in_kbps)) {
                bitrate = download_info.bitrate_in_kbps;
                dl_info_uri = download_info.download_info_url;
            }
        }

        return yield form_download_url (
            dl_info_uri,
            priority,
            cancellable
        );
    }

    public async Gee.ArrayList<DownloadInfo> tracks_download_info (
        string track_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        Bytes bytes = yield soup_wrapper.get (
            @"$(YAM_BASE_URL)/tracks/$track_id/download-info",
            { "default" },
            null,
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var di_array = new Gee.ArrayList<DownloadInfo> ();
        yield jsoner.deserialize_array (di_array);

        return di_array;
    }

    async string form_download_url (
        string dl_info_url,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        Bytes bytes = yield get_content_of (
            dl_info_url,
            priority,
            cancellable
        );
        string xml_string = (string) bytes.get_data ();

        Xml.Parser.init ();
        var doc = Xml.Parser.parse_memory (xml_string, xml_string.length);

        var root = doc->get_root_element ();

        var children = root->children;
        var host = children->get_content ();

        children = children->next;
        var path = children->get_content ();

        children = children->next;
        var ts = children->get_content ();

        children = children->next;
        children = children->next;
        var s = children->get_content ();

        var str = "XGRlBW9FXlekgbPrRHuSiA" + path[1:] + s;
        var sign = Checksum.compute_for_string (ChecksumType.MD5, str, str.length);

        return @"https://$host/get-mp3/$sign/$ts/$path";
    }

    public async Lyrics track_lyrics (
        string track_id,
        bool is_sync,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        string format = is_sync ? "LRC" : "TEXT";
        string timestamp = new DateTime.now_utc ().to_unix ().to_string ();
        string msg = @"$track_id$timestamp";

        var hmac = new Hmac (ChecksumType.SHA256, "p93jhgh689SBReK6ghtw62".data);
        hmac.update (msg.data);
        uint8[] hmac_sign = new uint8[32];
        size_t digest_length = 32;
        hmac.get_digest (hmac_sign, ref digest_length);
        string sign = Base64.encode (hmac_sign);

        Bytes bytes = yield soup_wrapper.get (
            @"$(YAM_BASE_URL)/tracks/$track_id/lyrics",
            { "default" },
            {
                { "format", format },
                { "timeStamp", timestamp },
                { "sign", sign }
            },
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        var lyrics = (Lyrics) yield jsoner.deserialize_object (typeof (Lyrics));
        lyrics.is_sync = is_sync;

        return lyrics;
    }

    public async SimilarTracks tracks_similar (
        string track_id,
        int priority = Priority.DEFAULT,
        Cancellable? cancellable = null
    ) throws ClientError, BadStatusCodeError {
        Bytes bytes = yield soup_wrapper.get (
            @"$(YAM_BASE_URL)/tracks/$track_id/similar",
            { "default" },
            null,
            null,
            priority,
            cancellable
        );
        var jsoner = Jsoner.from_bytes (bytes, { "result" }, Case.CAMEL);

        return (SimilarTracks) yield jsoner.deserialize_object (typeof (SimilarTracks));
    }
}
