module fs

import os
import pkg
import store

pub fn install(info pkg.PkgInfo, db &store.DB, staging string, target_root string) ! {
	for file in info.files {
		src := os.join_path(info.root, file)
		dst := os.join_path(staging, file)

		if !os.exists(src) {
			return error('missing file: ${src}')
		}

		// conflict check
		owner := db.owner(file)!

		if owner != '' && owner != info.name {
			return error('file owned by ${owner}: ${file}')
		}

		// ensure dir exists
		dir := os.dir(dst)
		if !os.exists(dir) {
			os.mkdir_all(dir)!
		}

		os.cp(src, dst)!
	}

	for file in info.files {
		src := os.join_path(staging, file)
		dst := os.join_path(target_root, file)

		dir := os.dir(dst)
		if !os.exists(dir) {
			os.mkdir_all(dir)!
		}

		println('installing ${src} to ${dst}')
		os.cp(src, dst)!
	}
}
