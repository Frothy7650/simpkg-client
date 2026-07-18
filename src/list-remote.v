module main

import store

fn cmd_list_remote(target_root string) ! {
	mut db := store.open(target_root)!
	packages := db.list_remote()

	for package in packages {
		println('${package.name} ${package.version}, source: ${package.source}')
	}
}
