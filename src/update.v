module main

import frothy7650.dag
import net.http
import store
import os

fn cmd_update() ! {
	println('fetching ${config.dag_url}')
	body := http.get(config.dag_url)!.body

	mut g := dag.new_graph()
	g.from_json(body)!

	os.write_file(store.remote_path, body)!
	println('done')
}
