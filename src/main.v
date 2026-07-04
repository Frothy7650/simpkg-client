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
		'list-local' {
			cmd_list_local() or { eprintln(err.msg()) }
			return
		}
    'list-remote' {
			cmd_list_remote() or { eprintln(err.msg()) }
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
		'search-local' { cmd_search_local(val) or { eprintln(err.msg()) } }
    'search-remote' { cmd_search_remote(val) or { eprintln(err.msg()) } }
    'files' { cmd_files(val) or { eprintln(err.msg()) } }
		else { eprintln('unknown command') }
	}
}

fn print_usage() {
	eprintln('usage: simpkg {install|remove|query|owns|search|files|update|list|clear-cache} [target]')
}
