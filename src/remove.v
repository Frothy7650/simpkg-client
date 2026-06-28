module main

import os
import fs
import store

fn cmd_remove(name string) ! {
	mut db := store.open() or {
		eprintln(err.msg())
		return
	}

	info := db.get_local(name) or {
		eprintln(err.msg())
		return
	}

  if info.preremoves.len > 0 { println('running preremove hooks...') }
  for cmd in info.preremoves {
    res := os.system(cmd)
    if res != 0 {
      return error('preremove command failed with exit code ${res}: ${cmd}')
    }
  }

	for f in info.files {
		println('removing ${f}')
		os.rm(os.join_path(fs.system_root(), f)) or { eprintln('failed: ${f}') }
	}

  if info.postremoves.len > 0 { println('running postremove hooks...') }
  for cmd in info.postremoves {
    res := os.system(cmd)
    if res != 0 {
      return error('postremove command failed with exit code ${res}: ${cmd}')
    }
  }

	db.delete_local(name) or { eprintln(err.msg()) }
}
