module fs

import os
import pkg
import store

// install into staging first, then commit
pub fn install(info pkg.PkgInfo, db &store.DB, staging string) ! {
	target_root := '/'

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

	// commit stage → root
	for file in info.files {
		os.cp(os.join_path(staging, file), os.join_path(target_root, file))!
	}
}

// dependency check (simplified but stable)
pub fn check_deps(deps []string) ! {
	for d in deps {
		if !os.exists_in_system_path(d) {
			return error('missing dependency: ${d}')
		}
	}
}
