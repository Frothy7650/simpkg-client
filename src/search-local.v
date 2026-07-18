module main

import strings
import store

fn cmd_search_local(name string, target_root string) ! {
	mut db := store.open(target_root)!

	packages := db.list_local()!

	mut scored := []LocalScored{}

	for package in packages {
		score := strings.levenshtein_distance(package.name.to_lower(), name.to_lower())
		scored << LocalScored{
			package: package
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
		res := scored[i].package
		println('${res.name} ${res.version}')
	}
}

struct LocalScored {
	package store.Package
	score   int
}
