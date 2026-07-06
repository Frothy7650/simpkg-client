module fs

import dl
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

// Dependency types:
// pacman:<package>
// dpkg:<package>
// pkgconfig:<pkg-config module>
// lib:<shared library>
// binary:<executable in PATH>

fn dep_exists(dep string) bool {
	name := dep.trim_space()

	// pacman
	$if linux {
		if name.starts_with('pacman:') {
			package := name[7..]
			if package.len == 0 {
				return false
			}
			res := os.exec(['pacman', '-Q', package])
			return res.exit_code == 0
		}
	}

	// apt
	$if linux {
		if name.starts_with('dpkg:') {
			package := name[5..]
			if package.len == 0 {
				return false
			}
			res := os.exec(['dpkg', '-l', package])
			return res.exit_code == 0
		}
	}

	// pkg-config
	if name.starts_with('pkgconfig:') {
		mod := name[4..]
		if mod.len == 0 {
			return false
		}
		$if !windows {
			res := os.exec(['pkg-config', '--exists', mod])
			return res.exit_code == 0
		}
		return false
	}

	// binary
	if name.starts_with('binary:') {
		bin := name[7..]
		return os.exists_in_system_path(bin)
	}

	// shared lib
	if name.starts_with('lib:') {
		lib := name[4..]

		$if linux {
			res := os.exec(['ldconfig', '-p'])
			if res.output.contains(lib) && res.exit_code == 0 {
				return true
			}

			handle := dl.open_opt(lib, dl.rtld_lazy) or { return false }
			dl.close(handle)
			return true
		}

		$if macos {
			handle := dl.open_opt(lib, dl.rtld_lazy) or { return false }
			dl.close(handle)
			return true
		}

		return false
	}

	return os.exists_in_system_path(dep)
}

pub fn check_deps(deps []string) ! {
	mut missing := []string{}
	for dep in deps {
		if !dep_exists(dep) {
			missing << dep
		}
	}
	if missing.len > 0 {
		return error('Missing dependencies: ${missing}')
	}
}
