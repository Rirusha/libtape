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

[CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "config.h")]
namespace Config {
    public const string LIBRARY_NAME;
    public const string APP_ID;
    public const string APP_NAME;
    public const string APP_NAME_LOWER;
    public const string VERSION;
    public const string G_LOG_DOMAIN;
    public const string GETTEXT_PACKAGE;
    public const string GNOMELOCALEDIR;
    public const string DATADIR;

    // mpris
    public const bool CAN_CONTROL;
    public const bool CAN_QUIT;
    public const bool CAN_RAISE;
    public const bool CAN_SET_FULLSCREEN;
}
