module main

import store

fn cmd_owns(path string) ! {
	mut db := store.open()!

	owner := db.owner(path.trim_left('/'))!

	if owner == '' {
		println('untracked (possibly system file)')
	} else {
		println('${path} owned by ${owner}')
	}
}
