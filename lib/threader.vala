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

public delegate void Tape.ThreadFunc ();

/**
 * Thread information that should be run.
 */
public sealed class Tape.ThreadInfo {

    weak ThreadFunc func;
    Cancellable cancellable;

    public ThreadInfo (ThreadFunc func, Cancellable cancellable) {
        this.func = func;
        this.cancellable = cancellable;
    }

    /**
     * Start function.
     */
    public void run () {
        if (!cancellable.is_cancelled ()) {
            func ();
        }
    }
}

/**
 * Thread queue realization.
 */
public sealed class Tape.WorkManager : Object {

    AsyncQueue<ThreadInfo> thread_datas = new AsyncQueue<ThreadInfo> ();

    Mutex mutex = Mutex ();
    Cond cond = Cond ();

    int running_jobs_count = 0;
    public int max_running_jobs { get; construct; }

    public WorkManager (int max_running_jobs) {
        Object (max_running_jobs: max_running_jobs);
    }

    construct {
        new Thread<void> (null, work);
    }

    void work () {
        while (true) {
            mutex.lock ();

            if (running_jobs_count >= max_running_jobs) {
                cond.wait (mutex);
            }

            lock (running_jobs_count) {
                running_jobs_count++;
            }

            new Thread<void> (null, () => {
                var worker = thread_datas.pop ();
                worker.run ();

                lock (running_jobs_count) {
                    running_jobs_count--;
                }

                cond.signal ();
            });

            mutex.unlock ();
        }
    }

    /**
     * Add func to worker.
     */
    public void add (ThreadFunc func, Cancellable? cancellable) {
        thread_datas.push (new ThreadInfo (
                                           func,
                                           cancellable != null ? cancellable : new Cancellable ()
        ));
    }
}

/**
 * Thread manager.
 */
public sealed class Tape.Threader {

    static WorkManager regular_pool;
    static WorkManager image_pool;
    static WorkManager audio_pool;
    static WorkManager cache_pool;
    static WorkManager single_pool;

    /**
     * Init Threader.
     */
    public static void init (int max_thread_number) {
        if (regular_pool != null) {
            Logger.error (_("Threader already initted"));
        }

        regular_pool = new WorkManager (max_thread_number * 2);
        image_pool = new WorkManager (max_thread_number);
        audio_pool = new WorkManager (max_thread_number);
        cache_pool = new WorkManager (max_thread_number / 2);
        single_pool = new WorkManager (1);
    }

    /**
     * Run func in another thread.
     *
     * @param func          function should be run in another thread
     * @param cancellable   should function be run. Already started function
     *                      cannot be cancelled
     */
    public static void add (ThreadFunc func,

                            Cancellable? cancellable = null) {
        if (regular_pool == null) {
            Logger.error (_("Threader not initted"));
        }

        regular_pool.add (func, cancellable);
    }

    /**
     * Run func in another thread. For images.
     *
     * @param func          function should be run in another thread
     * @param cancellable   should function be run. Already started function
     *                      cannot be cancelled
     */
    public static void add_image (ThreadFunc func,
                                  Cancellable? cancellable = null) {
        if (image_pool == null) {
            Logger.error (_("Threader not initted"));
        }

        image_pool.add (func, cancellable);
    }

    /**
     * Run func in another thread. For audio.
     *
     * @param func          function should be run in another thread
     * @param cancellable   should function be run. Already started function
     *                      cannot be cancelled
     */
    public static void add_audio (ThreadFunc func,
                                  Cancellable? cancellable = null) {
        if (audio_pool == null) {
            Logger.error (_("Threader not initted"));
        }

        audio_pool.add (func, cancellable);
    }

    /**
     * Run func in another thread. For Job class.
     *
     * @param func          function should be run in another thread
     * @param cancellable   should function be run. Already started function
     *                      cannot be cancelled
     */
    public static void add_cache (ThreadFunc func,
                                  Cancellable? cancellable = null) {
        if (cache_pool == null) {
            Logger.error (_("Threader not initted"));
        }

        cache_pool.add (func, cancellable);
    }

    /**
     * Run func in another thread. Run one thread at once.
     *
     * @param func          function should be run in another thread
     * @param cancellable   should function be run. Already started function
     *                      cannot be cancelled
     */
    public static void add_single (ThreadFunc func,
                                   Cancellable? cancellable = null) {
        if (single_pool == null) {
            Logger.error (_("Threader not initted"));
        }

        single_pool.add (func, cancellable);
    }
}
