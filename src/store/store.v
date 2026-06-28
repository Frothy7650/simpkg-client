module store

import db.sqlite
import net.http
import json
import time
import pkg
import os

pub const db_path = os.join_path(store_dir(), 'local.db')
pub const remote_path = os.join_path(store_dir(), 'remote.json')

pub const remote_url = $if windows { 'https://simpkg.frothy7650.org/api/windows' } $else $if linux { 'https://simpkg.frothy7650.org/api/linux' }

fn store_dir() string {
	$if windows {
		return os.join_path(os.state_dir(), 'simpkg')
	}
	return '/var/lib/simpkg'
}

pub struct DB {
pub mut:
	local  sqlite.DB
	remote []JsonPackage
}

pub struct Package {
pub mut:
	name    string @[primary; unique]
	version string
	deps    string
  preremoves  string
  postremoves string
	time    time.Time
}

pub struct File {
pub mut:
	name string
	path string
}

pub struct JsonPackage {
pub mut:
	name    string
	version string
	source  string
}

pub fn open() !DB {
	if !os.exists(store_dir()) {
		os.mkdir_all(store_dir())!
	}

	if !os.exists(db_path) {
		os.create(db_path)!
	}

	if !os.exists(remote_path) {
		os.create(remote_path)!
		os.write_file(remote_path, '[]')!
	}

	mut local := sqlite.connect(db_path)!

	sql local {
		create table Package
	}!

	sql local {
		create table File
	}!

	mut remote := json.decode([]JsonPackage, os.read_file(remote_path)!)!

	return DB{
		local:  local
		remote: remote
	}
}

pub fn (mut db DB) register(info pkg.PkgInfo) ! {
	p := Package{
		name:    info.name
		version: info.version
		deps:    json.encode(info.deps)
    preremoves: json.encode(info.preremoves)
    postremoves: json.encode(info.postremoves)
		time:    time.now()
	}

	sql db.local {
		delete from Package where name == info.name
	}!
	sql db.local {
		delete from File where name == info.name
	}!

	sql db.local {
		insert p into Package
	}!

	for f in info.files {
		file := File{
			name: info.name
			path: f
		}
		sql db.local {
			insert file into File
		}!
	}
}

pub fn (db &DB) get_local(name string) !pkg.PkgInfo {
	rows := sql db.local {
		select from Package where name == name
	}!

	if rows.len == 0 {
		return error('package not found')
	}

	mut info := pkg.PkgInfo{
		name:    rows[0].name
		version: rows[0].version
		deps:    json.decode([]string, rows[0].deps) or { []string{} }
    preremoves: json.decode([]string, rows[0].preremoves) or { []string{} }
    postremoves: json.decode([]string, rows[0].postremoves) or { []string{} }
	}

	files := sql db.local {
		select from File where name == name
	}!

	for f in files {
		info.files << f.path
	}

	return info
}

pub fn (db &DB) get_remote(name string) !JsonPackage {
	mut package := JsonPackage{}
	mut found := false

	for pkg in db.remote {
		if pkg.name == name {
			package = pkg
			found = true
			break
		}
	}

	if !found {
		return error('package not found')
	}

	return package
}

pub fn (db &DB) list_local() ![]Package {
  packages := sql db.local {
    select from Package
  }!

  return packages
}

pub fn (db &DB) delete_local(name string) ! {
	sql db.local {
		delete from Package where name == name
	}!
	sql db.local {
		delete from File where name == name
	}!
}

pub fn (db &DB) owner(path string) !string {
	mut files := sql db.local {
		select from File where path == path
	}!

	if files.len == 0 {
		return ''
	}

	if files.len > 1 {
		return error('multiple owners for ${path}')
	}

	return files[0].name
}

pub fn (db &DB) update_remote() ! {
  println('fetching ${remote_url}')
	remote := http.get(remote_url)!.body
	os.write_file(remote_path, remote)!
  println('done')
}
