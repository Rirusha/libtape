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

namespace CassetteClient.YaMAPI.Rotor {

    namespace ValueHeapType {
        public const string DISCRETE_SCALE = "discrete-scale";
        public const string ENUM = "enum";
    }

    namespace StationLanguage {
        public const string NOT_RUSSIAN = "not-russian";
        public const string RUSSIAN = "russian";
        public const string ANY = "any";
    }

    namespace MoodEnergy {
        public const string FUN = "fun";
        public const string ACTIVE = "active";
        public const string CALM = "calm";
        public const string SAD = "sad";
        public const string ALL = "all";
    }

    namespace Diversity {
        public const string FAVORITE = "favorite";
        public const string POPULAR = "popular";
        public const string DISCOVER = "discover";
        public const string DEFAULT = "default";
    }

    namespace FeedbackType {
        public const string RADIO_STARTED = "radioStarted";
        public const string TRACK_STARTED = "trackStarted";
        public const string SKIP = "skip";
        public const string TRACK_FINISHED = "trackFinished";
        public const string RADIO_FINISHED = "radioFinished";
        public const string LIKE = "like";
        public const string UNLIKE = "unlike";
        public const string DISLIKE = "dislike";
        public const string UNDISLIKE = "undislike";
    }

    namespace StationType {
        public const string ON_YOUR_WAVE = "user:onyourwave";
        public const string COLLECTION = "personal:collection";
    }
}
