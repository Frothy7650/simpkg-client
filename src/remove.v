module main

import os
import store

fn cmd_remove(name string, target_root string) ! {
	mut db := store.open(target_root) or {
		eprintln(err.msg())
		return
	}

	info := db.get_local(name) or {
		eprintln(err.msg())
		return
	}

	if info.preremove.len > 0 { println('running preremove hooks...') }
	for cmd in info.preremove {
		res := os.system(cmd)
		if res != 0 {
			return error('preremove command failed with exit code ${res}: ${cmd}')
		}
	}

	for f in info.files {
		println('removing ${f}')
		os.rm(os.join_path(target_root, f)) or { eprintln('failed: ${f}') }
	}

	if info.postremove.len > 0 { println('running postremove hooks...') }
	for cmd in info.postremove {
		res := os.system(cmd)
		if res != 0 {
			return error('postremove command failed with exit code ${res}: ${cmd}')
		}
	}

	db.delete_local(name) or { eprintln(err.msg()) }
}
