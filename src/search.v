module main

import strings
import store

fn cmd_search(name string) ! {
	mut db := store.open()!

	if db.remote.len == 0 {
		return
	}

	mut scored := []Scored{}

	for package in db.remote {
		score := strings.levenshtein_distance(package.name.to_lower(), name.to_lower())
		scored << Scored{
			package: package
			score: score
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

struct Scored {
  package store.JsonPackage
  score   int
}
