module main

import store

fn cmd_files(name string) ! {
	mut db := store.open()!

	info := db.get_local(name)!

	println('files:\n${info.files.join_lines()}')
}
