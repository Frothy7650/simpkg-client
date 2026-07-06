module main

import os

fn main() {
	mut args := arguments()
	if os.getuid() != 0 && os.user_os() != 'windows' {
		os.system('sudo ${args.join(' ')}')
		return
	}

	if args.len < 2 {
		print_usage()
		return
	}

	mut target_root := $if windows { 'C:\\' } $else { '/' }

	for i := 0; i < args.len; i++ {
		if args[i].starts_with('--root=') {
			parts := args[i].split_nth('=', 2)

			if parts.len != 2 || parts[0] == '' || parts[1] == '' {
				eprintln('invalid flag ${args[i]}')
				return
			}

			target_root = parts[1]
			println('using specified root: ${target_root}')
			args.delete(i)
			break
		}
	}

	cmd := args[1]

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

	if args.len < 3 {
		print_usage()
		return
	}

	targets := args[2..].clone()

	match cmd {
		'install' {
			for target in targets {
				cmd_install(target, target_root) or { eprintln(err.msg()) }
			}
		}
		'remove' {
			for target in targets {
				cmd_remove(target, target_root) or { eprintln(err.msg()) }
			}
		}
		'query' {
			for target in targets {
				cmd_query(target) or { eprintln(err.msg()) }
			}
		}
		'owns' {
			for target in targets {
				cmd_owns(target, target_root) or { eprintln(err.msg()) }
			}
		}
		'search-local' {
			for target in targets {
				cmd_search_local(target) or { eprintln(err.msg()) }
			}
		}
		'search-remote' {
			for target in targets {
				cmd_search_remote(target) or { eprintln(err.msg()) }
			}
		}
		'files' {
			for target in targets {
				cmd_files(target) or { eprintln(err.msg()) }
			}
		}
		else {
			eprintln('unknown command')
		}
	}
}

fn print_usage() {
	eprintln('usage: simpkg [install|remove|query|owns|search-local|search-remote|files|update|list-local|list-remote|clear-cache] <target>')
}
