module main

import os
import store

fn cmd_remove(name string) {
	mut db := store.open() or {
		eprintln(err.msg())
		return
	}

	info := db.get_local(name) or {
		eprintln(err.msg())
		return
	}

	for f in info.files {
		println('removing ${f}')
		os.rm('/' + f) or {
			eprintln('failed: ${f}')
		}
	}

	db.delete_local(name) or {
		eprintln(err.msg())
	}
}
