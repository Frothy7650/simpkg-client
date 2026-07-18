module store

import db.sqlite
import net.http
import json2
import time
import frothy7650.dag
import pkg
import os

pub fn store_dir(root string) string {
	$if windows {
		return os.join_path(root, os.state_dir(), 'simpkg')
	}
	return os.join_path(root, '/var/lib/simpkg')
}

pub fn db_path(root string) string {
	return os.join_path(store_dir(root), 'local.db')
}

pub fn remote_path(root string) string {
	return os.join_path(store_dir(root), 'remote.json')
}

pub struct DB {
pub mut:
	root   string
	local  sqlite.DB
	remote dag.Graph
}

pub struct Package {
pub mut:
	name       string @[primary; unique]
	version    string
	depends    string
	preremove  string
	postremove string
	time       time.Time
}

pub struct File {
pub mut:
	name string
	path string
}

// RemotePackage is a package entry resolved from the remote dependency graph.
pub struct RemotePackage {
pub:
	name    string
	version string
	source  string
	depends []string
}

// open opens (creating if necessary) the local store rooted at `root`.
// Pass '' (or '/') for the real system root; pass a directory to have the
// store, its database, and the remote package cache live under that
// directory instead — e.g. for `--root=/mnt/chroot` installs.
pub fn open(root string) !DB {
	dir := store_dir(root)
	local_db_path := db_path(root)
	local_remote_path := remote_path(root)

	if !os.exists(dir) {
		os.mkdir_all(dir)!
	}

	if !os.exists(local_db_path) {
		os.create(local_db_path)!
	}

	if !os.exists(local_remote_path) {
		os.create(local_remote_path)!
		os.write_file(local_remote_path, dag.new_graph().as_json())!
	}

	mut local := sqlite.connect(local_db_path)!

	sql local {
		create table Package
	}!

	sql local {
		create table File
	}!

	mut remote := dag.new_graph()
	remote.from_json(os.read_file(local_remote_path)!)!

	return DB{
		root:   root
		local:  local
		remote: remote
	}
}

pub fn (mut db DB) register(info pkg.PkgInfo) ! {
	p := Package{
		name:       info.name
		version:    info.version
		depends:    json2.encode(info.depends)
		preremove:  json2.encode(info.preremove)
		postremove: json2.encode(info.postremove)
		time:       time.now()
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

  for link, _ in info.symlinks {
    file := File{
      name: info.name
      path: link
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
		name:       rows[0].name
		version:    rows[0].version
		depends:    json2.decode[[]string](rows[0].depends) or { []string{} }
		preremove:  json2.decode[[]string](rows[0].preremove) or { []string{} }
		postremove: json2.decode[[]string](rows[0].postremove) or { []string{} }
	}

	files := sql db.local {
		select from File where name == name
	}!

	for f in files {
		info.files << f.path
	}

	return info
}

// check_deps returns the subset of `deps` that are not yet installed locally.
pub fn (db &DB) check_deps(deps []string) []string {
	mut needed := []string{}

	for dep in deps {
		db.get_local(dep) or { needed << dep }
	}

	return needed
}

// get_remote looks up a package directly in the remote dependency graph.
pub fn (db &DB) get_remote(name string) !RemotePackage {
	if name !in db.remote.nodes {
		return error('remote package not found: ${name}')
	}

	node := db.remote.nodes[name]

	return RemotePackage{
		name:    node.id
		version: node.version
		source:  node.source
		depends: db.remote.immediate_deps(name)
	}
}

pub fn (db &DB) list_local() ![]Package {
	packages := sql db.local {
		select from Package
	}!

	return packages
}

// list_remote returns every package known to the remote dependency graph.
pub fn (db &DB) list_remote() []RemotePackage {
	mut packages := []RemotePackage{}

	for id, node in db.remote.nodes {
		packages << RemotePackage{
			name:    id
			version: node.version
			source:  node.source
			depends: db.remote.edges[id]
		}
	}

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

// update_dag fetches the latest dependency graph — which now doubles as the
// remote package list (name, version, source, and deps) — and persists it.
pub fn (mut db DB) update_dag(dag_url string) ! {
	println('fetching ${dag_url}')
	body := http.get(dag_url)!.body

	mut g := dag.new_graph()
	g.from_json(body)!

	os.write_file(remote_path(db.root), body)!
	db.remote = g
	println('done')
}
