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

public struct Tape.PostContent {

    PostContentType content_type;
    string content;

    public string get_content_type_string () {
        switch (content_type) {
        case X_WWW_FORM_URLENCODED:
            return "application/x-www-form-urlencoded";
        case JSON:
            return "application/json";
        default:
            assert_not_reached ();
        }
    }

    public Bytes get_bytes () {
        return new Bytes (content.data);
    }

    public void set_datalist (Datalist<string> datalist) {
        switch (content_type) {
        case X_WWW_FORM_URLENCODED:
            content = Soup.Form.encode_datalist (datalist);
            break;
        case JSON:
            content = Jsoner.serialize_datalist (datalist);
            break;
        default:
            assert_not_reached ();
        }
    }
}
