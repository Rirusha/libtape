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

/**
 * `YaMObject` that has cover.
 */
public interface CassetteClient.YaMAPI.HasCover: YaMObject {

    /**
     * Get all `YaMObject` covers.
     *
     * @param size  cover size
     *
     * @return      covers array  
     */
    public abstract Gee.ArrayList<string> get_cover_items_by_size (int size);
}
