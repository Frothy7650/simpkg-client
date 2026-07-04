module fs

import v.pkgconfig
import os
import pkg
import store

pub fn install(info pkg.PkgInfo, db &store.DB, staging string) ! {
	target_root := system_root()

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

		os.cp(src, dst)!
	}
}

// Check existence of one dependency
fn dep_exists(dep string) bool {
	name := dep.trim_space()

	// Attempt pkg-config first (skip on Windows if no pkg-config).
	// Assuming non-Windows or environment has pkg-config.
	$if !windows {
		// v.pkgconfig takes module names without extension
		mut opts := pkgconfig.Options{}
		// If dep ends in .pc, strip it for module name
		modname := if name.ends_with('.pc') { name[..name.len - 3] } else { name }
		if modname.len > 0 {
			if mut _ := pkgconfig.load(modname, opts) {
				// Found .pc for module; check any libs from it if needed
				return true
			}
		}
	}

	// If dep looks like a shared library name:
	$if linux {
		// On Linux, try ldconfig
		res := os.exec(['ldconfig', '-p'])
		// ldconfig output lines like: libexpat.so.1 (libc6,x86-64) => /usr/lib/x86_64...
		if res.output.contains(name) {
			return true
		}
		// If not found in ldconfig, check common lib paths
		mut libdirs := ['/lib', '/usr/lib', '/usr/lib64', '/lib64', '/usr/local/lib']
		// Also include multiarch dirs on Debian/Ubuntu
		libdirs << [
			'/usr/lib/x86_64-linux-gnu',
			'/usr/lib/i386-linux-gnu',
			'/usr/lib/aarch64-linux-gnu',
			'/usr/lib/arm-linux-gnueabihf',
		]
		for dir in libdirs {
			path := os.join_path(dir, name)
			if os.exists(path) {
				return true
			}
		}
		// Try dlopen (ignore error)
		cname := name.str
		handle := C.dlopen(cname, C.RTLD_LAZY)
		if handle != 0 {
			C.dlclose(handle)
			return true
		}
		return false
	} $else $if windows {
		// On Windows, ensure .dll extension
		mut dll := name
		if !dll.to_lower().ends_with('.dll') {
			dll += '.dll'
		}
		// Check PATH
		if os.exists_in_system_path(dll) {
			return true
		}
		// Check system directories explicitly
		sysroot := os.getenv_opt('SystemRoot') or { '' }
		mut dirs := ['']
		if sysroot.len > 0 {
			dirs << os.join_path(sysroot, 'System32')
			dirs << os.join_path(sysroot, 'SysWOW64')
		}
		dirs << os.join_path(os.getenv('ProgramFiles'), dll) // naive
		for dir in dirs {
			if dir == '' { continue
			 }
			path := os.join_path(dir, dll)
			if os.exists(path) {
				return true
			}
		}
		// Try LoadLibrary (with null to free handle)
		handle := C.LoadLibraryA(dll.str) // ensure C string
		if handle != 0 {
			C.FreeLibrary(handle)
			return true
		}
		return false
	} $else $if macos {
		// On macOS, try known lib paths and dlopen
		libdirs := ['/usr/lib', '/usr/local/lib']
		libdirs << os.join_path(os.getenv('HOME'), 'opt/homebrew/lib') // user Homebrew
		libdirs << ['/opt/homebrew/lib', '/usr/local/lib'] // common prefixes
		for dir in libdirs {
			path := os.join_path(dir, name)
			if os.exists(path) {
				return true
			}
		}
		handle := C.dlopen(name.cstr(), C.RTLD_LAZY)
		if handle != 0 {
			C.dlclose(handle)
			return true
		}
		return false
	} $else {
		return os.exists_in_system_path(name)
	}
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

pub fn system_root() string {
	$if windows {
		return 'C:\\'
	}
	return '/'
}
