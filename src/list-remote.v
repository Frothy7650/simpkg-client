module main

import store

fn cmd_list_remote() ! {
	mut db := store.open()!
	packages := db.list_remote()!

	for package in packages {
		println('${package.name} ${package.version}, source: ${package.source}')
	}
}
