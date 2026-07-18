module fs

import os
import pkg
import store


pub fn install(info pkg.PkgInfo, db &store.DB, staging string, target_root string) ! {
	// Stage files
	for file in info.files {
		src := os.join_path(info.root, file)
		dst := os.join_path(staging, file)

		os.lstat(src) or {
			return error('missing file: ${src}')
		}

		owner := db.owner(file)!

		if owner != '' && owner != info.name {
			return error('file owned by ${owner}: ${file}')
		}

		install_entry(src, dst)!
	}


	// Create symlinks in staging
	for link, target in info.symlinks {
		dst := os.join_path(staging, link)

		remove_entry(dst)!

		parent := os.dir(dst)
		os.mkdir_all(parent)!

		os.symlink(target, dst)!
	}


	// Commit staging to system root
	for file in info.files {
		src := os.join_path(staging, file)
		dst := os.join_path(target_root, file)

		println('installing ${src} -> ${dst}')

		install_entry(src, dst)!
	}


	// Commit symlinks
	for link, _ in info.symlinks {
		src := os.join_path(staging, link)
		dst := os.join_path(target_root, link)

		remove_entry(dst)!

		parent := os.dir(dst)
		os.mkdir_all(parent)!

		target_path := os.readlink(src)!

		os.symlink(target_path, dst)!
	}
}


fn install_entry(src string, dst string) ! {
	info := os.lstat(src)!

	match info.get_filetype() {

		.directory {
			if !os.exists(dst) {
				os.mkdir_all(dst)!
			}
		}


		.symbolic_link {
			remove_entry(dst)!

			parent := os.dir(dst)
			os.mkdir_all(parent)!

			target := os.readlink(src)!

			os.symlink(target, dst)!
		}


		.regular {
			remove_entry(dst)!

			parent := os.dir(dst)
			os.mkdir_all(parent)!

			os.cp(src, dst)!
		}


		else {
			return error('unsupported file type: ${src}')
		}
	}
}


fn remove_entry(path string) ! {
	info := os.lstat(path) or {
		return
	}

	match info.get_filetype() {

		.directory {
			os.rmdir_all(path)!
		}

		.symbolic_link {
			os.rm(path)!
		}

		.regular {
			os.rm(path)!
		}

		else {}
	}
}
