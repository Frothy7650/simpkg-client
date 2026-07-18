module main

import store

fn cmd_files(name string, target_root string) ! {
	mut db := store.open(target_root)!

	info := db.get_local(name)!

	println('files:\n${info.files.join_lines()}')
}
