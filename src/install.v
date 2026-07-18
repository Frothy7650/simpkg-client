module main

import net.http
import os
import pkg
import store
import fs

fn cache_dir() string {
	$if windows {
		return os.join_path(os.cache_dir(), 'simpkg')
	}

	return '/var/cache/simpkg'
}

fn temp_dir() string {
	return os.join_path(os.temp_dir(), 'simpkg')
}

fn prepare_temp() !(string, string) {
	root := temp_dir()

	extract := os.join_path(root, 'extract')
	stage := os.join_path(root, 'stage')

	for dir in [extract, stage] {
		if os.exists(dir) {
			os.rmdir_all(dir)!
		}
		os.mkdir_all(dir)!
	}

	return extract, stage
}

fn fetch_package(package store.RemotePackage) !string {
	cache := cache_dir()

	os.mkdir_all(cache)!

	archive := os.join_path(cache, '${package.name}-${package.version}.simpkg')

	if !os.exists(archive) {
		println('downloading ${package.name}...')
		http.download_file(package.source, archive)!
	}

	return archive
}

// cmd_install resolves the full dependency chain for `name` via the DAG
// and installs whatever isn't already present, in topological order.
fn cmd_install(name string, target_root string) ! {
	mut db := store.open()!

	order := db.remote.install_order(name) or {
		return error('failed to resolve dependencies for ${name}: ${err.msg()}')
	}

	mut to_install := []string{}
	for id in order {
		if id == name {
			to_install << id
			continue
		}
		db.get_local(id) or { to_install << id }
	}

	if to_install.len > 1 {
		println('installing dependencies:')
		for id in to_install {
			if id != name {
				println('\t${id}')
			}
		}
	}

	for pkg_name in to_install {
		install_one(mut db, pkg_name, target_root)!
	}
}

fn install_one(mut db store.DB, name string, target_root string) ! {
	remote := db.get_remote(name)!

	archive := fetch_package(remote)!

	extract_dir, staging_dir := prepare_temp()!

	root := pkg.open(archive, extract_dir)!
	info := pkg.parse(root)!

	if info.build.len > 0 {
		println('running build commands, this may take a while...')
		os.setenv('SIMPKG_ROOT', extract_dir, true)
		mut p := get_system_shell()

		p.work_folder = extract_dir
		p.set_redirect_stdio()
		p.run()

		for cmd in info.build {
			p.stdin_write(cmd + '\n')
		}
		p.stdin_write('exit\n')

		for {
			out := p.stdout_read()
			if out != '' {
				print(out)
			}

			err := p.stderr_read()
			if err != '' {
				eprint(err)
			}

			if !p.is_alive() {
				break
			}
		}

		p.wait()

		if p.code != 0 {
			return error('build failed with exit code ${p.code}')
		}
	}

	for file in info.files {
		owner := db.owner(file)!

		if owner != '' && owner != info.name {
			return error('conflict: ${file} owned by ${owner}')
		}
	}

	if info.preinstall.len > 0 { println('running preinstall hooks...') }
	for cmd in info.preinstall {
		res := os.system(cmd)
		if res != 0 {
			return error('preinstall command failed with exit code ${res}: ${cmd}')
		}
	}

	println('installing ${info.name} ${info.version}')

	fs.install(info, &db, staging_dir, target_root)!

	if info.postinstall.len > 0 { println('running postinstall hooks...') }
	for cmd in info.postinstall {
		res := os.system(cmd)
		if res != 0 {
			return error('postinstall command failed with exit code ${res}: ${cmd}')
		}
	}

	db.register(info)!
}

fn get_system_shell() &os.Process {
	$if windows {
		mut p := os.new_process('C:\\WINDOWS\\system32\\cmd.exe')
		p.args = ['/k']
		return p
	} $else {
		mut p := os.new_process('/bin/sh')
		p.args = ['-s']
		return p
	}
}
