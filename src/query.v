module main

import store

fn cmd_query(name string, target_root string) ! {
	mut db := store.open(target_root)!

	info := db.get_local(name)!

	println('name: ${info.name}')
	println('version: ${info.version}')
	println('depends: ${info.depends.join(', ')}')
}
