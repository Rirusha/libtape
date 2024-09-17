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

/**
 * A class for working with client files
 */
public class Tape.Storager : Object {

    InfoDB? _db = null;
    public InfoDB db {
        get {
            if (_db == null) {
                _db = new InfoDB (db_file.peek_path ());

                Logger.info (_("Database was initialized, loc - %s").printf (db.db_path));
            }

            return _db;
        }
    }

    // Permanent root dir
    File _data_dir_file;
    public File data_dir_file {
        get {
            lock (_data_dir_file) {
                create_dir_if_not_existing (_data_dir_file);
            }

            return _data_dir_file;
        }
    }

    // Permanent images dir
    File _data_images_dir_file;
    public File data_images_dir_file {
        get {
            lock (_data_images_dir_file) {
                create_dir_if_not_existing (_data_images_dir_file);
            }

            return _data_images_dir_file;
        }
    }

    // Permanent audios dir
    File _data_audios_dir_file;
    public File data_audios_dir_file {
        get {
            lock (_data_audios_dir_file) {
                create_dir_if_not_existing (_data_audios_dir_file);
            }

            return _data_audios_dir_file;
        }
    }

    // Permanent objects dir
    File _data_objects_dir_file;
    public File data_objects_dir_file {
        get {
            lock (_data_objects_dir_file) {
                create_dir_if_not_existing (_data_objects_dir_file);
            }

            return _data_objects_dir_file;
        }
    }

    // Temporary root dir
    File _cache_dir_file;
    public File cache_dir_file {
        get {
            lock (_cache_dir_file) {
                create_dir_if_not_existing (_cache_dir_file);
            }

            return _cache_dir_file;
        }
    }

    // Temporary images dir
    File _cache_images_dir_file;
    public File cache_images_dir_file {
        get {
            lock (_cache_images_dir_file) {
                create_dir_if_not_existing (_cache_images_dir_file);
            }

            return _cache_images_dir_file;
        }
    }

    // Temporary audios dir
    File _cache_audios_dir_file;
    public File cache_audios_dir_file {
        get {
            lock (_cache_audios_dir_file) {
                create_dir_if_not_existing (_cache_audios_dir_file);
            }

            return _cache_audios_dir_file;
        }
    }

    // Temporary objects dir
    File _cache_objects_dir_file;
    public File cache_objects_dir_file {
        get {
            lock (_cache_objects_dir_file) {
                create_dir_if_not_existing (_cache_objects_dir_file);
            }

            return _cache_objects_dir_file;
        }
    }

    File _log_file;
    public File log_file {
        get {
            file_exists (_log_file);

            return _log_file;
        }
    }

    File _db_file;
    public File db_file {
        get {
            file_exists (_db_file);

            return _db_file;
        }
    }

    File _cookies_file;
    public File cookies_file {
        get {
            file_exists (_cookies_file);

            return _cookies_file;
        }
    }

    File temp_audio_file;
    string temp_audio_uri;

    construct {
        _data_dir_file = File.new_build_filename (Environment.get_user_data_dir (), Filenames.ROOT_DIR_NAME);

        _db_file = File.new_build_filename (data_dir_file.peek_path (), Filenames.DATABASE);
        _cookies_file = File.new_build_filename (data_dir_file.peek_path (), Filenames.COOKIES);

        _data_images_dir_file = File.new_build_filename (data_dir_file.peek_path (), Filenames.IMAGES);
        _data_audios_dir_file = File.new_build_filename (data_dir_file.peek_path (), Filenames.AUDIOS);
        _data_objects_dir_file = File.new_build_filename (data_dir_file.peek_path (), Filenames.OBJECTS);


        _cache_dir_file = File.new_build_filename (Environment.get_user_cache_dir (), Filenames.ROOT_DIR_NAME);

        _log_file = File.new_build_filename (cache_dir_file.peek_path (), Filenames.LOG);
        Logger.log_file = _log_file;

        _cache_images_dir_file = File.new_build_filename (cache_dir_file.peek_path (), Filenames.IMAGES);
        _cache_audios_dir_file = File.new_build_filename (cache_dir_file.peek_path (), Filenames.AUDIOS);
        _cache_objects_dir_file = File.new_build_filename (cache_dir_file.peek_path (), Filenames.OBJECTS);

        temp_audio_file = File.new_build_filename (cache_dir_file.peek_path (), ".track");
        temp_audio_uri = "file://%s".printf (temp_audio_file.peek_path ());

        Logger.debug ("Storager initialized");
    }

    public async void move_loc_to_temp_async (Location loc,
                                              bool can_cache) {
        /**
            Переместить файл во временное хранилище, если он в постоянном
         */

        if (loc.file != null && loc.is_tmp == false) {
            if (can_cache) {
                yield move_file_to_async (loc.file,
                                          true);
            } else {
                yield remove_file_async (loc.file);
            }
        }
    }

    public async void move_loc_to_perm_async (Location loc) {
        /**
            Переместить файл в постоянное хранилище, если он во временном
         */

        yield move_file_to_async (loc.file,
                                  false);
    }

    static bool file_exists (File target_file) {
        if (target_file.query_exists ()) {
            return true;
        } else {
            Logger.info ("Location '%s' was not found.".printf (target_file.peek_path ()));

            return false;
        }
    }

    static void create_dir_if_not_existing (File target_file) {
        if (!file_exists (target_file)) {
            try {
                target_file.make_directory_with_parents ();

                Logger.info ("Directory '%s' created".printf (target_file.peek_path ()));
            } catch (Error e) {
                Logger.error ("Error while creating directory '%s'. Error message: %s".printf (
                                  target_file.peek_path (),
                                  e.message
                                  ));
            }
        }
    }

    public async void move_to_async (string src_path,
                                     bool is_tmp) {
        yield move_file_to_async (File.new_for_path (src_path),
                                  is_tmp);
    }

    public async void move_file_to_async (File src_file,
                                          bool is_tmp) {
        var b = src_file.peek_path ().split ("/tape/");

        File dst_file = File.new_build_filename (
            is_tmp ? cache_dir_file.peek_path () : data_dir_file.peek_path (),
            b[b.length - 1]
            );

        yield move_file_async (src_file,
                               dst_file);
    }

    async void move_file_async (File src_file,
                                File dst_file) {
        /**
            Перемещает файл
         */

        try {
            yield src_file.move_async (dst_file,
                                       FileCopyFlags.OVERWRITE,
                                       Priority.DEFAULT,
                                       null,
                                       null);
        } catch (Error e) {
            Logger.warning ("Can't move file '%s' to '%s'. Error message: %s".printf (
                                src_file.peek_path (),
                                dst_file.peek_path (),
                                e.message
                                ));
        }
    }

    async void move_file_dir_async (File src_dir_file,
                                    File dst_dir_file) {
        /**
            Перемещает директорию рекурсивно
         */

        try {
            FileEnumerator? enumerator = src_dir_file.enumerate_children (
                "standard::*",
                FileQueryInfoFlags.NONE,
                null
                );

            if (enumerator != null) {
                FileInfo? file_info = null;

                while ((file_info = enumerator.next_file ()) != null) {
                    string file_name = file_info.get_name ();

                    File src_file = File.new_build_filename (src_dir_file.peek_path (), file_name);
                    File dst_file = File.new_build_filename (dst_dir_file.peek_path (), file_name);

                    if (file_info.get_file_type () == FileType.DIRECTORY) {
                        yield move_file_dir_async (src_file,
                                                   dst_file);
                    } else if (file_info.get_file_type () == FileType.REGULAR) {
                        yield move_file_async (src_file,
                                               dst_file);
                    } else {
                        yield src_file.trash_async ();

                        Logger.warning (
                            "In cache folder found suspicious file '%s'. It moved to trash.".printf (file_name)
                            );
                    }
                }
            }

            yield src_dir_file.delete_async ();
        } catch (Error e) {
            Logger.warning ("Can't move directory '%s' to '%s'. Error message: %s".printf (
                                src_dir_file.peek_path (),
                                dst_dir_file.peek_path (),
                                e.message
                                ));
        }
    }

    /**
     * Delete file with error handle.
     */
    public async static void remove_file_async (File target_file) {
        try {
            yield target_file.delete_async ();
        } catch (Error e) {
            Logger.warning ("Can't delete file '%s'. Error message: %s".printf (
                                target_file.peek_path (),
                                e.message
                                ));
        }
    }

    public async static void remove_async (string file_path) {
        yield remove_file_async (File.new_for_path (file_path));
    }

    async void remove_dir_file_async (File dir_file) {

        try {
            FileEnumerator? enumerator = dir_file.enumerate_children (
                "standard::*",
                FileQueryInfoFlags.NONE,
                null
                );

            if (enumerator != null) {
                FileInfo? file_info = null;

                while ((file_info = enumerator.next_file ()) != null) {
                    string file_name = file_info.get_name ();

                    File file = File.new_build_filename (dir_file.peek_path (), file_name);

                    if (file_info.get_file_type () == FileType.DIRECTORY) {
                        yield remove_dir_file_async (file);
                    } else if (file_info.get_file_type () == FileType.REGULAR) {
                        yield remove_file_async (file);
                    } else {
                        yield file.trash_async ();

                        Logger.warning (
                            "In cache folder found suspicious file '%s'. It moved to trash.".printf (file_name)
                            );
                    }
                }
            }

            dir_file.delete ();
        } catch (Error e) {
            Logger.warning ("Can't remove directory '%s'. Error message: %s".printf (
                                dir_file.peek_path (),
                                e.message
                                ));
        }
    }

    /**
     * Remove user data and move content to cache
     *
     * @param keep_content  remove content or keep
     * @param keep_settings remove cookies and other or
     */
    public async void clear_user_data_async (bool keep_content,
                                             bool keep_datadir) {
        if (keep_content) {
            yield move_file_dir_async (data_images_dir_file,
                                       cache_images_dir_file);
            yield move_file_dir_async (data_objects_dir_file,
                                       cache_objects_dir_file);
            yield move_file_dir_async (data_audios_dir_file,
                                       cache_audios_dir_file);
        }

        _db = null;
        yield remove_file_async (db_file);

        if (!keep_datadir) {
            yield remove_dir_file_async (data_dir_file);
        }
    }

    public async void delete_cache_dir_async () {
        /**
            Удаляет временные файлы
         */

        yield remove_dir_file_async (cache_dir_file);
    }

    /**
     * Simple encoding to protect DRM content from direct access.
     * Please do not publish an uncoded version on the Internet and do
     * not distribute a workaround (albeit a simple one).
     * This may cause the client developers to have problems with Yandex.
     */
    void simple_dencode (ref uint8[] data) {
        for (int i = 0; i < data.length; i++) {
            data[i] = data[i] ^ 0xFF;
        }
    }

    string replace_many (string input,
                         char[] targets,
                         char replacement) {
        var builder = new StringBuilder ();

        for (int i = 0; i < input.length; i++) {
            if (input[i] in targets) {
                builder.append_c (replacement);
            } else {
                builder.append_c (input[i]);
            }
        }

        return builder.free_and_steal ();
    }

    string encode_name (string name) {
        return replace_many (Base64.encode (name.data), { '/', '+', '=' }, '-');
    }

    /////////////
    // Images  //
    /////////////

    File get_image_cache_file (string image_uri,
                               bool is_tmp) {
        return File.new_build_filename (
            is_tmp ? cache_images_dir_file.peek_path () : data_images_dir_file.peek_path (),
            encode_name (image_uri)
            );
    }

    /**
     * Get image location by it uri.
     *
     * @param   image uri
     *
     * @return  `Location` struct
     */
    public Location image_cache_location (string image_uri) {
        File image_file;

        image_file = get_image_cache_file (image_uri, false);
        if (image_file.query_exists ()) {
            return Location (false, image_file);
        }

        image_file = get_image_cache_file (image_uri, true);
        if (image_file.query_exists ()) {
            return Location (true, image_file);
        }

        return Location.none ();
    }

    public async uint8[] ? load_image_async (string image_uri) {
        Location image_location = image_cache_location (image_uri);

        if (image_location.file == null) {
            return null;
        }

        for (int i = 0; i > 5; i++) {
            try {
                uint8[] image_data;
                yield image_location.file.load_contents_async (null,
                                                               out image_data,
                                                               null);

                simple_dencode (ref image_data);

                return image_data;
            } catch (Error e) {
                Logger.warning ("Can't load image '%s'. Error message: %s".printf (
                                    image_location.file.peek_path (),
                                    e.message
                                    ));

                yield wait_async (3);
            }
        }

        Logger.warning ("Give up loading image '%s'.".printf (
                            image_location.file.peek_path ()
                            ));
        return null;
    }

    public async void save_image_async (owned uint8[] image_data,
                                        string image_url,
                                        bool is_tmp = true) {
        File image_file = get_image_cache_file (image_url, is_tmp);

        try {
            simple_dencode (ref image_data);

            yield image_file.replace_contents_async (image_data,
                                                     null,
                                                     false,
                                                     FileCreateFlags.NONE,
                                                     null,
                                                     null);
        } catch (Error e) {
            Logger.warning (("Can't save image %s".printf (image_url)));
        }
    }

    /////////////
    // Audios  //
    /////////////

    File get_audio_cache_file (string track_id,
                               bool is_tmp) {
        return File.new_build_filename (
            is_tmp ? cache_audios_dir_file.peek_path () : data_audios_dir_file.peek_path (),
            encode_name (track_id)
            );
    }

    public Location audio_cache_location (string track_id) {
        File track_file;

        track_file = get_audio_cache_file (track_id, false);
        if (track_file.query_exists ()) {
            return Location (false, track_file);
        }

        track_file = get_audio_cache_file (track_id, true);
        if (track_file.query_exists ()) {
            return Location (true, track_file);
        }

        return Location.none ();
    }

    public async uint8[] ? load_audio_data_async (string track_id) {
        Location audio_location = audio_cache_location (track_id);

        if (audio_location.file == null) {
            return null;
        }

        for (int i = 0; i > 5; i++) {
            try {
                uint8[] audio_data;
                yield audio_location.file.load_contents_async (null,
                                                               out audio_data,
                                                               null);

                simple_dencode (ref audio_data);

                return audio_data;
            } catch (Error e) {
                Logger.warning ("Can't load audio '%s'. Error message: %s".printf (
                                    audio_location.file.peek_path (),
                                    e.message
                                    ));

                yield wait_async (3);
            }
        }

        Logger.warning ("Give up loading track with id '%s'.".printf (
                            track_id
                            ));
        return null;
    }

    // Расшифровывает трек, помещает его во временные файлы и даёт его uri
    public async string ? load_audio_async (string track_id) {
        var track_data = yield load_audio_data_async (track_id);

        if (track_data != null) {
            try {
                yield temp_audio_file.replace_contents_async (track_data,
                                                              null,
                                                              false,
                                                              FileCreateFlags.NONE,
                                                              null,
                                                              null);

                return temp_audio_uri;
            } catch (Error e) {
                Logger.warning ("Can't save temp audio. Error message: %s".printf (
                                    e.message
                                    ));

                yield wait_async (3);
            }

            Logger.warning ("Give up saving temp track with id '%s'.".printf (
                                track_id
                                ));
            return null;
        } else {
            return null;
        }
    }

    public async void clear_temp_audio_async () {
        yield remove_file_async (temp_audio_file);
    }

    /**
     * Save audio data.
     *
     * @param audio_data    audio data. It will be decode and can't be use after
     * @param track_id      track's id
     * @param is_tmp        is track should be save in cache or data
     */
    public async void save_audio_async (owned uint8[] audio_data,
                                        string track_id,
                                        bool is_tmp) {
        File audio_file = get_audio_cache_file (track_id, is_tmp);

        try {
            simple_dencode (ref audio_data);

            yield audio_file.replace_contents_async (audio_data,
                                                     null,
                                                     false,
                                                     FileCreateFlags.NONE,
                                                     null,
                                                     null);
        } catch (Error e) {
            Logger.warning (("Can't save audio %s".printf (
                                 track_id
                                 )));
        }
    }

    ///////////////
    // Objects  //
    ///////////////

    string build_id (Type build_type,
                     string oid) {
        return build_type.name () + "-" + oid;
    }

    public async YaMAPI.HasTracks[] get_saved_objects_async () {
        var obj_arr = new Array<YaMAPI.HasTracks> ();

        try {
            FileEnumerator? enumerator = data_objects_dir_file.enumerate_children (
                "standard::*",
                FileQueryInfoFlags.NONE,
                null
                );

            if (enumerator != null) {
                FileInfo? file_info = null;

                string filename;
                File file;
                string decoded_name;
                Type obj_type;

                while ((file_info = enumerator.next_file ()) != null) {
                    filename = file_info.get_name ();
                    file = File.new_build_filename (data_objects_dir_file.peek_path (), filename);

                    decoded_name = (string) (Base64.decode (filename));

                    if ((typeof (YaMAPI.Playlist)).name () in decoded_name) {
                        obj_type = typeof (YaMAPI.Playlist);
                    } else if ((typeof (YaMAPI.Album)).name () in decoded_name) {
                        obj_type = typeof (YaMAPI.Album);
                    } else {
                        continue;
                    }

                    uint8[] idata;
                    yield file.load_contents_async (null,
                                                    out idata,
                                                    null);

                    simple_dencode (ref idata);

                    var jsoner = Jsoner.from_data (idata);

                    Threader.add (() => {
                        try {
                            obj_arr.append_val ((YaMAPI.HasTracks) jsoner.deserialize_object (obj_type));
                        } catch (ClientError e) {
                            Logger.warning (("Can't parse object. Error message: %s".printf (
                                                 e.message
                                                 )));
                        }

                        Idle.add (get_saved_objects_async.callback);
                    });

                    yield;
                }
            }
        } catch (Error e) {
            Logger.warning ("Can't find '%s'. Error message: %s".printf (
                                data_objects_dir_file.peek_path (),
                                e.message
                                ));
        }

        return obj_arr.data;
    }

    File get_object_cache_file (Type obj_type,
                                string oid,
                                bool is_tmp) {
        return File.new_build_filename (
            is_tmp ? cache_objects_dir_file.peek_path () : data_objects_dir_file.peek_path (),
            encode_name (build_id (obj_type, oid))
            );
    }

    public Location object_cache_location (Type obj_type,
                                           string oid) {
        File object_file;

        object_file = get_object_cache_file (obj_type, oid, false);
        if (object_file.query_exists ()) {
            return Location (false, object_file);
        }

        object_file = get_object_cache_file (obj_type, oid, true);
        if (object_file.query_exists ()) {
            return Location (true, object_file);
        }

        return Location.none ();
    }

    public async YaMAPI.HasID? load_object_async (Type obj_type, string oid) {
        Location object_location = object_cache_location (obj_type, oid);

        if (object_location.file == null) {
            return null;
        }

        for (int i = 0; i > 5; i++) {
            try {
                uint8[] object_data;

                yield object_location.file.load_contents_async (null,
                                                                out object_data,
                                                                null);

                simple_dencode (ref object_data);

                var jsoner = Jsoner.from_data (object_data);

                YaMAPI.HasID? des_obj = null;

                Threader.add (() => {
                    try {
                        des_obj = (YaMAPI.HasID) jsoner.deserialize_object (obj_type);
                    } catch (ClientError e) {
                        Logger.warning (("Can't parse object. Error message: %s".printf (
                                             e.message
                                             )));
                    }

                    Idle.add (load_object_async.callback);
                });

                yield;

                return des_obj;
            } catch (Error e) {
                Logger.warning ("Can't load object '%s'. Error message: %s".printf (
                                    object_location.file.peek_path (),
                                    e.message
                                    ));

                yield wait_async (3);
            }
        }

        Logger.warning ("Give up loading object '%s'.".printf (
                            object_location.file.peek_path ()
                            ));
        return null;
    }

    public async void save_object_async (YaMAPI.HasID yam_object,
                                         bool is_tmp) {
        File object_file = get_object_cache_file (yam_object.get_type (), yam_object.oid, is_tmp);

        try {
            uint8[] object_data;

            Threader.add (() => {
                object_data = Jsoner.serialize (yam_object).data;

                Idle.add (save_object_async.callback);
            });

            yield;

            simple_dencode (ref object_data);

            yield object_file.replace_contents_async (object_data,
                                                      null,
                                                      false,
                                                      FileCreateFlags.NONE,
                                                      null,
                                                      null);
        } catch (Error e) {
            Logger.warning (_("Can't save object %s").printf (yam_object.get_type ().name ()));
        }
    }

    /////////////
    // Other  //
    /////////////

    public async HumanitySize get_temp_size_async () {
        string size = "";

        Threader.add (() => {
            try {
                Process.spawn_command_line_sync ("du -sh %s --exclude=\"*.log\"".printf (
                                                     cache_dir_file.peek_path ()
                                                     ), out size);

                Regex regex = null;
                regex = new Regex ("^[\\d.,]+[A-Z]", RegexCompileFlags.OPTIMIZE, RegexMatchFlags.NOTEMPTY);

                MatchInfo match_info;

                if (regex.match (size, 0, out match_info)) {
                    size = match_info.fetch (0);
                } else {
                    size = "";
                }
            } catch (Error e) {
                Logger.warning (_("Error while getting cache directory size. Error message %s").printf (
                                    e.message
                                    ));
            }

            Idle.add (get_temp_size_async.callback);
        });

        yield;

        if (size != "") {
            return to_human (size);
        } else {
            return to_human ("0B");
        }
    }

    public async HumanitySize get_perm_size_async () {
        string size = "";

        Threader.add (() => {
            try {
                Process.spawn_command_line_sync ("du -sh %s --exclude=\"*.db\" --exclude=\"*.cookies\"".printf (
                                                     data_dir_file.peek_path ()
                                                     ), out size);

                Regex regex = null;
                regex = new Regex ("^[\\d.,]+[A-Z]", RegexCompileFlags.OPTIMIZE, RegexMatchFlags.NOTEMPTY);

                MatchInfo match_info;

                if (regex.match (size, 0, out match_info)) {
                    size = match_info.fetch (0);
                } else {
                    size = "";
                }
            } catch (Error e) {
                Logger.warning (_("Error while getting cache directory size. Error message %s").printf (
                                    e.message
                                    ));
            }

            Idle.add (get_perm_size_async.callback);
        });

        yield;

        if (size != "") {
            return to_human (size);
        } else {
            return to_human ("0B");
        }
    }
}
