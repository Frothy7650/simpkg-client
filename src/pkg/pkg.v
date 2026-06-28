module pkg

import compress.szip
import os

pub enum PkgType {
	binary
	source
	library
}

pub struct PkgInfo {
pub mut:
	name    string
	version string
	type_   PkgType
	deps    []string
	files   []string
  preinstalls  []string
  postinstalls []string
  preremoves   []string
  postremoves  []string
	root    string
}

// Extract .simpkg into a temp folder
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

// Parse PKGINFO/metadata (NOW A FILE, NOT DIRECTORY)
pub fn parse(root string) !PkgInfo {
	pkginfo_path := os.join_path(root, 'PKGINFO')

	if !os.exists(pkginfo_path) {
		return error('missing PKGINFO: ${pkginfo_path}')
	}

	lines := os.read_file(pkginfo_path)!.split_into_lines()

	mut pkg := PkgInfo{
		root: root
	}

	for line in lines {
		if line.trim_space() == '' || line.starts_with('#') {
			continue
		}

		parts := line.split_nth('=', 2)
		if parts.len != 2 {
			return error('invalid PKGINFO line: ${line}')
		}

		key := parts[0]
		val := parts[1]

		match key {
			'name' {
				pkg.name = val
			}
			'version' {
				pkg.version = val
			}
			'type' {
				match val {
					'binary' { pkg.type_ = .binary }
					'source' { pkg.type_ = .source }
					'library' { pkg.type_ = .library }
					else { return error('invalid type: ${val}') }
				}
			}
			'depends' {
				pkg.deps << val
			}
			'files' {
				pkg.files << val
			}
      'preinstall' {
        pkg.preinstalls << val
      }
      'postinstall' {
        pkg.postinstalls << val
      }
      'preremove' {
        pkg.preremoves << val
      }
      'postremove' {
        pkg.postremoves << val
      }
			else {
				return error('unknown key: ${key}')
			}
		}
	}

	if pkg.name == '' {
		return error('missing package name')
	}

	return pkg
}
