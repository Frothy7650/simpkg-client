module main

import store

fn cmd_owns(path string, system_root string) ! {
	mut db := store.open(system_root)!

	owner := db.owner(path.trim_left(system_root))!

	if owner == '' {
		println('untracked (possibly system file)')
	} else {
		println('${path} owned by ${owner}')
	}
}
