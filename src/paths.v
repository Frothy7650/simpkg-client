module main

import os
import store
import frothy7650.dag

// ensure_paths guarantees every filesystem path the program depends on
// exists before any command runs, creating whatever is missing:
//   - the user config dir (always the real system, never --root)
//   - the local store dir, its sqlite db, and the remote package cache
//   - the download cache dir
// The store and cache are rooted under `target_root`; config never is.
fn ensure_paths(target_root string) ! {
	if !os.exists(config_dir) {
		os.mkdir_all(config_dir)!
	}

	store_dir := store.store_dir(target_root)
	if !os.exists(store_dir) {
		os.mkdir_all(store_dir)!
	}

	db_path := store.db_path(target_root)
	if !os.exists(db_path) {
		os.create(db_path)!
	}

	remote_path := store.remote_path(target_root)
	if !os.exists(remote_path) {
		os.create(remote_path)!
		os.write_file(remote_path, dag.new_graph().as_json())!
	}

	cache := cache_dir(target_root)
	if !os.exists(cache) {
		os.mkdir_all(cache)!
	}
}
