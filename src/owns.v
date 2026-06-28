module main

import store
import fs

fn cmd_owns(path string) ! {
	mut db := store.open()!

	owner := db.owner(path.trim_left(fs.system_root()))!

	if owner == '' {
		println('untracked (possibly system file)')
	} else {
		println('${path} owned by ${owner}')
	}
}
