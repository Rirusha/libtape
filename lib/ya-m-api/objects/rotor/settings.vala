/* Copyright 2023-2024 Rirusha
 *
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
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-only
 */

using Gee;

/**
 * Wave settings.
 */
public class CassetteClient.YaMAPI.Rotor.Settings: YaMObject {

    /**
     *
     */
    public Station default_station { get; set; }

    /**
     *
     */
    public ArrayList<Block> blocks { get; set; default = new ArrayList<Block> (); }

    /**
     *
     */
    public Restrictions setting_restrictions { get; set; }
}
