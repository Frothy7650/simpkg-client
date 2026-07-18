module main

import store

fn cmd_list_local(target_root string) ! {
	mut db := store.open(target_root)!
	packages := db.list_local()!

	for package in packages {
		println('${package.name} ${package.version}')
	}
}
