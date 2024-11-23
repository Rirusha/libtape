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

using Gee;
using ApiBase;

public sealed class Tape.Jsoner : ApiBase.Jsoner {

    public Jsoner (
        string json_string,
        string[]? sub_members = null,
        Case names_case = Case.KEBAB
    ) throws CommonError {
        this (json_string, sub_members, names_case);
    }

    /**
     * Метод для десериализации данных о библиотеке пользователя.
     * Существует, так как API возвращает json, в котором вместо списков с id
     * решили каждый элемент списка сделать отдельным элементом json объекта.
     *
     * @return  десериализованный объект
     */
    public async YaMAPI.Library.AllIds deserialize_lib_data () throws CommonError {
        var lib_data = new YaMAPI.Library.AllIds ();

        var node = root;

        if (node.get_node_type () != Json.NodeType.OBJECT) {
            Logger.warning (_("Wrong type: expected %s, got %s").printf (
                Json.NodeType.OBJECT.to_string (), node.get_node_type ().to_string ()
            ));
            throw new CommonError.PARSE_JSON ("Node isn't object");
        }

        var ld_obj = node.get_object ();

        foreach (var ld_type_name in ld_obj.get_members ()) {
            var ld_type_obj = ld_obj.get_member (ld_type_name).get_object ();

            if (ld_type_name == "defaultLibrary") {
                foreach (var ld_val_name in ld_type_obj.get_members ()) {
                    if (ld_type_obj.get_int_member (ld_val_name) == 1) {
                        lib_data.liked_tracks.add (ld_val_name);

                    } else {
                        lib_data.disliked_tracks.add (ld_val_name);
                    }

                    Idle.add (deserialize_lib_data.callback);
                    yield;
                }
            } else if (ld_type_name == "artists") {
                foreach (var ld_val_name in ld_type_obj.get_members ()) {
                    if (ld_type_obj.get_int_member (ld_val_name) == 1) {
                        lib_data.liked_artists.add (ld_val_name);

                    } else {
                        lib_data.disliked_artists.add (ld_val_name);
                    }

                    Idle.add (deserialize_lib_data.callback);
                    yield;
                }
            } else {
                var tval = Value (Type.OBJECT);
                lib_data.get_property (camel2kebab (ld_type_name), ref tval);

                var lb = (Gee.ArrayList<string>) tval.get_object ();

                foreach (var ld_val_name in ld_type_obj.get_members ()) {
                    lb.add (ld_val_name);

                    Idle.add (deserialize_lib_data.callback);
                    yield;
                }
            }

            Idle.add (deserialize_lib_data.callback);
            yield;
        }

        return lib_data;
    }
}
