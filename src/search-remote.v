module main

import strings
import store

fn cmd_search_remote(name string, target_root string) ! {
	mut db := store.open(target_root)!

	if db.remote.nodes.len == 0 {
		return
	}

	mut scored := []RemoteScored{}

	for id, node in db.remote.nodes {
		score := strings.levenshtein_distance(id.to_lower(), name.to_lower())
		scored << RemoteScored{
			name:    id
			version: node.version
			score:   score
		}
	}

	if scored.len > 1 {
		scored.sort(a.score < b.score)
	}

	if scored.len == 0 {
		return
	}

	end := if scored.len < 5 { scored.len } else { 5 }

	for i in 0 .. end {
		res := scored[i]
		println('${res.name} ${res.version}')
	}
}

struct RemoteScored {
	name    string
	version string
	score   int
}
