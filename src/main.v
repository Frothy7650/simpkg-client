module main

import os

fn main() {
	if os.getuid() != 0 && os.user_os() != 'windows' {
		os.system('sudo ${os.args.join(' ')}')
		return
	}

	if os.args.len < 2 {
		print_usage()
		return
	}

	cmd := os.args[1]

	match cmd {
		'update' {
			cmd_update() or { eprintln(err.msg()) }
			return
		}
		'list' {
			cmd_list() or { eprintln(err.msg()) }
			return
		}
		'clear-cache' {
			cmd_clear_cache() or { eprintln(err.msg()) }
			return
		}
		else {}
	}

	if os.args.len < 3 {
		print_usage()
		return
	}

	val := os.args[2]

	match cmd {
		'install' { cmd_install(val) or { eprintln(err.msg()) } }
		'remove' { cmd_remove(val) or { eprintln(err.msg()) } }
		'query' { cmd_query(val) or { eprintln(err.msg()) } }
		'owns' { cmd_owns(val) or { eprintln(err.msg()) } }
		'search' { cmd_search(val) or { eprintln(err.msg()) } }
    'files' { cmd_files(val) or { eprintln(err.msg()) } }
		else { eprintln('unknown command') }
	}
}

fn print_usage() {
	eprintln('usage: simpkg {install|remove|query|owns|search|files|update|list|clear-cache} [target]')
}
