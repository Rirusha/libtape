/*
 * Copyright (C) 2024 Vladimir Romanov
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

using ApiBase;
using Tape.YaMAPI;

/**
 * Класс для выполнения всяких вещей, связанных с интернетом, чтобы
 * можно было оповестить пользователя о проблемах с соединением
 */
public sealed class Tape.YaMTalker : Object {

    public YaMAPI.Client yam_client { get; construct; }
    public LikesController likes_controller { get; default = new LikesController (); }

    public signal void connection_established ();
    public signal void connection_lost ();

    public signal void track_likes_start_change (string track_id);
    public signal void track_likes_end_change (string track_id, bool is_liked);

    public signal void track_dislikes_start_change (string track_id);
    public signal void track_dislikes_end_change (string track_id, bool is_disliked);

    public signal void playlist_changed (YaMAPI.Playlist new_playlist);
    public signal void playlists_updated ();
    public signal void playlist_start_delete (string oid);
    public signal void playlist_stop_delete (string oid);

    public signal void init_end ();

    Account.About? _me = null;
    public Account.About me {
        owned get {
            if (_me != null) {
                return _me;
            }

            _me = yam_client.me;
            if (_me == null) {
                string my_uid = root.cachier.storager.db.get_additional_data ("me");
                if (my_uid != null) {
                    _me = (Account.About) root.cachier.storager.load_object_sync (typeof (Account.About), my_uid);
                }

                if (_me == null) {
                    return new Account.About ();
                }
            }

            return _me;
        }
    }

    internal YaMTalker (
        string? cookies_path = null,
        string? token = null
    ) {
        assert ((cookies_path != null || token != null) && (cookies_path == null || token == null));

        YaMAPI.Client c;

        if (cookies_path != null) {
            c = new YaMAPI.Client.with_cookie (cookies_path, ApiBase.CookieJarType.DB);
        } else if (token != null) {
            c = new YaMAPI.Client.with_token (token);
        } else {
            assert_not_reached ();
        }

        Object (yam_client: c);
    }

    public async void init_if_not () throws BadStatusCodeError, CantUseError {
        bool is_need_init = false;

        if (yam_client == null) {
            is_need_init = true;
        } else {
            is_need_init = !yam_client.is_init_complete;
        }

        if (is_need_init) {
            yield init ();
        }

        if (me != null) {
            if (!me.has_plus) {
                throw new CantUseError.NO_PLUS ("No Plus Subscription");
            }
        }
    }

    async void prerun () throws CantUseError {
        try {
            yield init_if_not ();
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }
    }

    void postrun_success () {
        connection_established ();
    }

    void postrun_error_ignore_bad_code (Error e) throws CantUseError {
        try {
            postrun_error (e);
        } catch (BadStatusCodeError e) {}
    }

    void postrun_error (Error e) throws BadStatusCodeError, CantUseError {
        if (e is SoupError) {
            warning ("%s: %s".printf (
                e.domain.to_string (),
                e.message
            ));

            connection_lost ();
        } else if (e is BadStatusCodeError) {
            warning ("%s: %s".printf (
                e.domain.to_string (),
                e.message
            ));

            throw (BadStatusCodeError) e;
        } else if (e is CantUseError) {
            warning (
                "Can't use error: %s".printf (
                e.message
            ));
        } else {
            assert_not_reached ();
        }

        connection_lost ();
    }

    public bool is_me (string? uid) {
        return uid == null || uid == me.uid;
    }

    public bool is_my_liked (string? uid, string kind) {
        return is_me (uid) && kind == "3";
    }

    public async void init () throws BadStatusCodeError {
        try {
            yield yam_client.init ();

            root.cachier.storager.db.set_additional_data ("me", me.oid);
            root.cachier.storager.save_object (me, false);

            // TODO: replace with lib func
            yield get_playlist_info_old (null, "3");
            yield get_likes_playlist_list (null);
            yield get_disliked_tracks_short ();

            _me = null;

            init_end ();
        } catch (Error e) {
            postrun_error (e);
        }
    }

    // TODO: remove this
    public async Playlist? get_playlist_info_old (
        string? uid = null,
        string kind = "3"
    ) throws BadStatusCodeError, CantUseError {
        Playlist? playlist_info = null;

        yield prerun ();
        try {
            playlist_info = yield yam_client.users_playlists_playlist (kind, true, uid);

            if (is_my_liked (uid, kind)) {
                likes_controller.update_liked_tracks (playlist_info.tracks);
            }

            if (playlist_info.tracks.size != 0) {
                if (playlist_info.tracks[0].track == null) {
                    string[] tracks_ids = new string[playlist_info.tracks.size];
                    for (int i = 0; i < tracks_ids.length; i++) {
                        tracks_ids[i] = playlist_info.tracks[i].id;
                    }

                    var track_list = yield yam_client.tracks (tracks_ids);
                    playlist_info.set_track_list (track_list);
                }
            }

            // Сохраняет объект, если он не сохранен в data
            // Постоянными объектами занимается уже Cachier.Job
            var object_location = root.cachier.storager.object_cache_location (playlist_info.get_type (), playlist_info.oid);
            if (object_location.is_tmp && root.settings.can_cache) {
                root.cachier.storager.save_object (playlist_info, true);
                root.cachier.controller.change_state (
                    ContentType.PLAYLIST,
                    playlist_info.oid,
                    CacheingState.TEMP
                );
            }
        } catch (Error e) {
            postrun_error (e);
        }

        return playlist_info;
    }

    public async Playlist? get_playlist_info (string playlist_uuid) throws BadStatusCodeError, CantUseError {
        Playlist? playlist_info = null;

        yield prerun ();
        try {
            playlist_info = yield yam_client.playlist (playlist_uuid, false, true);

            if (is_my_liked (playlist_info.uid, playlist_info.kind)) {
                likes_controller.update_liked_tracks (playlist_info.tracks);
            }

            if (playlist_info.tracks.size != 0) {
                if (playlist_info.tracks[0].track == null) {
                    string[] tracks_ids = new string[playlist_info.tracks.size];
                    for (int i = 0; i < tracks_ids.length; i++) {
                        tracks_ids[i] = playlist_info.tracks[i].id;
                    }

                    var track_list = yield yam_client.tracks (tracks_ids);
                    playlist_info.set_track_list (track_list);
                }
            }

            // Сохраняет объект, если он не сохранен в data
            // Постоянными объектами занимается уже Cachier.Job
            var object_location = root.cachier.storager.object_cache_location (playlist_info.get_type (), playlist_info.oid);
            if (object_location.is_tmp && root.settings.can_cache) {
                root.cachier.storager.save_object (playlist_info, true);
                root.cachier.controller.change_state (
                    ContentType.PLAYLIST,
                    playlist_info.oid,
                    CacheingState.TEMP
                );
            }
        } catch (Error e) {
            postrun_error (e);
        }

        return playlist_info;
    }

    public async Gee.ArrayList<Track>? get_tracks_info (string[] ids) throws CantUseError {
        Gee.ArrayList<Track>? track_list = null;

        yield prerun ();
        try {
            track_list = yield yam_client.tracks (ids, true);
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return track_list;
    }

    public async void send_play (YaMAPI.Play[] play_objs) throws CantUseError {
        yield prerun ();
        try {
            yield yam_client.plays (play_objs);
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }
    }

    public async string? get_download_uri (string track_id, bool is_hq) throws CantUseError {
        string? track_uri = null;

        yield prerun ();
        try {
            track_uri = yield yam_client.track_download_url (track_id, is_hq);
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return track_uri;
    }

    public async void like (
        LikableType content_type,
        string content_id,
        string? playlist_owner = null,
        string? playlist_kind = null
    ) throws CantUseError {
        track_likes_start_change (content_id);
        bool is_ok = false;

        yield prerun ();
        try {
            switch (content_type) {
                case LikableType.TRACK:
                    is_ok = (yield yam_client.users_likes_tracks_add (content_id)) != 0;
                    break;

                case LikableType.PLAYLIST:
                    is_ok = yield yam_client.users_likes_playlists_add (content_id, playlist_owner, playlist_kind);
                    break;

                case LikableType.ALBUM:
                    is_ok = yield yam_client.users_likes_albums_add (content_id);
                    break;

                case LikableType.ARTIST:
                    is_ok = yield yam_client.users_likes_artists_add (content_id);
                    break;

                default:
                    assert_not_reached ();
            }
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        if (is_ok) {
            // Add artists support
            likes_controller.add_liked (content_type, content_id);
            track_likes_end_change (content_id, true);
            if (content_type == LikableType.TRACK) {
                likes_controller.remove_disliked (content_id);
                root.player.rotor_feedback (Rotor.FeedbackType.LIKE, content_id);

                track_dislikes_end_change (content_id, false);
            }
        }
    }

    public async void unlike (
        LikableType content_type,
        string content_id
    ) throws CantUseError {
        track_likes_start_change (content_id);
        bool is_ok = false;

        yield prerun ();
        try {
            switch (content_type) {
                case LikableType.TRACK :
                    is_ok = (yield yam_client.users_likes_tracks_remove (content_id)) != 0;
                    break;

                case LikableType.PLAYLIST :
                    is_ok = yield yam_client.users_likes_playlists_remove (content_id);
                    break;

                case LikableType.ALBUM:
                    is_ok = yield yam_client.users_likes_albums_remove (content_id);
                    break;

                case LikableType.ARTIST:
                    is_ok = yield yam_client.users_likes_artists_remove (content_id);
                    break;

                default:
                    assert_not_reached ();
            }
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        if (is_ok) {
            // Add artists support
            likes_controller.remove_liked (content_type, content_id);
            root.player.rotor_feedback (Rotor.FeedbackType.UNLIKE, content_id);

            track_likes_end_change (content_id, false);
        }
    }

    public async void dislike (
        DislikableType content_type,
        string content_id
    ) throws CantUseError {
        track_dislikes_start_change (content_id);
        bool is_ok = false;

        yield prerun ();
        try {
            switch (content_type) {
                case DislikableType.TRACK:
                    is_ok = (yield yam_client.users_dislikes_tracks_add (content_id)) != 0;
                    break;

                case DislikableType.ARTIST:
                    is_ok = yield yam_client.users_dislikes_artists_add (content_id);
                    break;

                default:
                    assert_not_reached ();
            }
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        if (is_ok) {
            // Add artists support
            likes_controller.add_disliked (content_id);
            root.player.rotor_feedback (Rotor.FeedbackType.DISLIKE, content_id);

            track_dislikes_end_change (content_id, true);
            likes_controller.remove_liked (LikableType.TRACK, content_id);
            track_likes_end_change (content_id, false);
        }
    }

    public async void undislike (
        DislikableType content_type,
        string content_id
    ) throws CantUseError {
        track_dislikes_start_change (content_id);
        bool is_ok = false;

        yield prerun ();
        try {
            switch (content_type) {
                case DislikableType.TRACK:
                    is_ok = (yield yam_client.users_dislikes_tracks_remove (content_id)) != 0;
                    break;

                case DislikableType.ARTIST:
                    is_ok = yield yam_client.users_dislikes_artists_remove (content_id);
                    break;

                default:
                    assert_not_reached ();
            }
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        if (is_ok) {
            // Add artists support
            likes_controller.remove_disliked (content_id);
            root.player.rotor_feedback (Rotor.FeedbackType.UNDISLIKE, content_id);

            track_dislikes_end_change (content_id, false);
        }
    }

    public async Gee.ArrayList<Playlist>? get_playlist_list (string? uid = null) throws CantUseError {
        Gee.ArrayList<Playlist>? playlist_list = null;

        yield prerun ();
        try {
            playlist_list = yield yam_client.users_playlists_list (uid);

            if (uid == null) {
                string[] playlists_kinds = new string[playlist_list.size];
                for (int i = 0; i < playlist_list.size; i++) {
                    playlists_kinds[i] = playlist_list[i].kind.to_string ();
                }

                root.cachier.storager.db.set_additional_data ("my_playlists", string.joinv (",", playlists_kinds));
            }
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return playlist_list;
    }

    public async Gee.ArrayList<LikedPlaylist>? get_likes_playlist_list (string? uid = null) throws CantUseError {
        Gee.ArrayList<LikedPlaylist>? playlist_list = null;

        yield prerun ();
        try {
            playlist_list = yield yam_client.users_likes_playlists (uid);

            likes_controller.update_liked_playlists (playlist_list);
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return playlist_list;
    }

    public async YaMAPI.SimilarTracks? get_track_similar (string track_id) throws CantUseError {
        YaMAPI.SimilarTracks? similar_tracks = null;

        yield prerun ();
        try {
            similar_tracks = yield yam_client.tracks_similar (track_id);
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return similar_tracks;
    }

    public async YaMAPI.Lyrics? get_lyrics (string track_id, bool is_sync) throws CantUseError {
        YaMAPI.Lyrics? lyrics = null;

        yield prerun ();
        try {
            lyrics = yield yam_client.track_lyrics (track_id, is_sync);
            var txt = yield load_text (lyrics.download_url);
            lyrics.text = new Gee.ArrayList<string>.wrap (txt.split ("\n"));
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return lyrics;
    }

    public async string? load_text (string uri) throws CantUseError {
        string? text = null;

        yield prerun ();
        try {
            Bytes? bytes = yield yam_client.get_content_of (uri);
            text = (string) bytes.get_data ();
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return text;
    }

    // Получает изображение из сети как pixbuf
    public async Bytes? load_image_data (string image_uri) throws CantUseError {
        Bytes? content = null;

        yield prerun ();
        try {
            content = yield yam_client.get_content_of (image_uri);
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return content;
    }

    public async Bytes? load_track (string track_uri) throws CantUseError {
        Bytes? content = null;

        yield prerun ();
        try {
            content = yield yam_client.get_content_of (track_uri);
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return content;
    }

    public async Playlist? add_track_to_playlist (Track track_info, Playlist playlist_info) throws CantUseError {
        return yield add_tracks_to_playlist ({ track_info }, playlist_info);
    }

    // playlist_info.kind,
    // track_info,
    // storager.settings.get_boolean ("add-tracks-to-start") ? 0 : playlist_info.track_count,
    // playlist_info.revision

    public async Playlist? add_tracks_to_playlist (
        Track[] tracks,
        Playlist playlist_info
    ) throws CantUseError {
        Playlist? new_playlist = null;

        var diff = new DifferenceBuilder ();

        diff.add_insert (
            root.settings.add_tracks_to_start ? 0 : playlist_info.track_count,
            tracks
        );

        yield prerun ();
        try {
            new_playlist = yield yam_client.users_playlists_change (
                null,
                playlist_info.kind,
                diff.to_json (),
                playlist_info.revision
            );
            playlist_changed (new_playlist);
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return new_playlist;
    }

    public async Playlist? remove_tracks_from_playlist (
        string kind,
        int position,
        int revision
    ) throws CantUseError {
        Playlist? new_playlist = null;

        var diff = new DifferenceBuilder ();

        diff.add_delete (position, position + 1);

        yield prerun ();
        try {
            new_playlist = yield yam_client.users_playlists_change (null, kind, diff.to_json (), revision);
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        playlist_changed (new_playlist);

        return new_playlist;
    }

    public async Playlist? change_playlist_visibility (
        string kind,
        bool is_public
    ) throws CantUseError {
        Playlist? new_playlist = null;

        yield prerun ();
        try {
            new_playlist = yield yam_client.users_playlists_visibility (null, kind, is_public ? "public" : "private");
            playlist_changed (new_playlist);
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return new_playlist;
    }

    public async Playlist? create_playlist () throws CantUseError {
        Playlist? new_playlist = null;

        yield prerun ();
        try {
            // Translators: name of new created playlist
            new_playlist = yield yam_client.users_playlists_create (null, _("New Playlist"));
            playlists_updated ();
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return new_playlist;
    }

    public async bool delete_playlist (string kind) throws CantUseError {
        bool is_success = false;

        yield prerun ();
        try {
            playlist_start_delete (kind);
            is_success = yield yam_client.users_playlists_delete (null, kind);
            if (is_success) {
                playlists_updated ();
            } else {
                playlist_stop_delete (kind);
            }
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return is_success;
    }

    public async Playlist? change_playlist_name (
        string kind,
        string new_name
    ) throws CantUseError {
        Playlist? new_playlist = null;

        yield prerun ();
        try {
            new_playlist = yield yam_client.users_playlists_name (null, kind, new_name);
            playlist_changed (new_playlist);
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return new_playlist;
    }

    async Gee.ArrayList<YaMAPI.TrackShort>? get_disliked_tracks_short () throws CantUseError {
        Gee.ArrayList<YaMAPI.TrackShort>? trackshort_list = null;

        yield prerun ();
        try {
            trackshort_list = yield yam_client.users_dislikes_tracks (null);

            likes_controller.update_disliked_tracks (trackshort_list);
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return trackshort_list;
    }

    public async YaMAPI.TrackHeap? get_disliked_tracks () throws CantUseError {
        YaMAPI.TrackHeap? track_list = null;

        yield prerun ();
        try {
            var trackshort_list = yield get_disliked_tracks_short ();

            string[] track_ids = new string[trackshort_list.size];
            for (int i = 0; i < track_ids.length; i++) {
                track_ids[i] = trackshort_list[i].id;
            }
            var tracks = yield yam_client.tracks (track_ids);
            track_list = new YaMAPI.TrackHeap ();
            track_list.tracks = tracks;
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return track_list;
    }

    public async Rotor.StationTracks? start_new_session (string station_id) throws CantUseError {
        Rotor.StationTracks? station_tracks = null;

        yield prerun ();
        try {
            var ses_new = new Rotor.SessionNew ();
            ses_new.seeds.add (station_id);

            station_tracks = yield yam_client.rotor_session_new (ses_new);
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return station_tracks;
    }

    public async void send_rotor_feedback (
        string radio_session_id,
        string batch_id,
        string feedback_type,
        string? track_id = null,
        double total_played_seconds = 0.0
    ) throws CantUseError {
        yield prerun ();
        try {
            var feedback_obj = new Rotor.Feedback () {
                event = new Rotor.Event () {
                    type_ = feedback_type,
                    track_id = track_id,
                    total_played_seconds = total_played_seconds
                },
                batch_id = batch_id
            };

            yield yam_client.rotor_session_feedback (
                radio_session_id,
                feedback_obj
            );
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }
    }

    public async Rotor.StationTracks? get_session_tracks (
        string radio_session_id,
        Gee.ArrayList<string> queue
    ) throws CantUseError {
        Rotor.StationTracks? station_tracks = null;

        yield prerun ();
        try {
            var ses_queue = new Rotor.Queue () {
                queue = queue
            };

            station_tracks = yield yam_client.rotor_session_tracks (radio_session_id, ses_queue);
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return station_tracks;
    }




    public async YaMAPI.Rotor.Dashboard? get_stations_dashboard () throws CantUseError {
        YaMAPI.Rotor.Dashboard? dashboard = null;

        yield prerun ();
        try {
            dashboard = yield yam_client.rotor_stations_dashboard ();
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return dashboard;
    }

    public async Gee.ArrayList<YaMAPI.Rotor.Station>? get_all_stations () throws CantUseError {
        Gee.ArrayList<YaMAPI.Rotor.Station>? stations_list = null;

        yield prerun ();
        try {
            stations_list = yield yam_client.rotor_stations_list ();
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return stations_list;
    }

    public async Rotor.Settings? get_wave_settings () throws CantUseError {
        Rotor.Settings? wave_settings = null;

        yield prerun ();
        try {
            wave_settings = yield yam_client.rotor_wave_settings ();
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return wave_settings;
    }

    public async Rotor.Wave? get_last_wave () throws CantUseError {
        Rotor.Wave? last_wave = null;

        yield prerun ();
        try {
            last_wave = yield yam_client.rotor_wave_last ();
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        return last_wave;
    }

    public async void reset_last_wave () throws CantUseError {
        bool is_success = false;

        yield prerun ();
        try {
            is_success = yield yam_client.rotor_wave_last_reset ();
        } catch (Error e) {
            postrun_error_ignore_bad_code (e);
        }

        yield;
    }
}
