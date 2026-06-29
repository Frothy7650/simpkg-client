module pkg

import compress.szip
import toml
import os

pub struct PkgInfo {
pub mut:
	name         string
	version      string
	deps         []string
	files        []string
  builds        []string
	preinstalls  []string
	postinstalls []string
	preremoves   []string
	postremoves  []string
	root         string
}

pub fn open(path string, out_dir string) !string {
	if !os.exists(path) {
		return error('package does not exist: ${path}')
	}

	if os.is_dir(path) {
		return error('package must be a file')
	}

	szip.extract_zip_to_dir(path, out_dir) or {
		return error('failed to extract package: ${err.msg()}')
	}

	return out_dir
}

pub fn parse(root string) !PkgInfo {
	pkginfo_path := os.join_path(root, 'PKGINFO')

	if !os.exists(pkginfo_path) {
		return error('missing PKGINFO: ${pkginfo_path}')
	}

	file := os.read_file(pkginfo_path)!

	mut pkg := toml.decode[PkgInfo](file)!
  pkg.root = root

	if pkg.name == '' {
		return error('missing package name')
	}
  if pkg.files.len == 0 {
    return error('missing package file list')
  }

	return pkg
}
