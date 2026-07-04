module main

import store

fn cmd_list_local() ! {
	mut db := store.open()!
	packages := db.list_local()!

	for package in packages {
		println('${package.name} ${package.version}')
	}
}
