module main

import store

fn cmd_update() ! {
	mut db := store.open()!

	db.update_remote()!
}

