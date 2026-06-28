// install.v
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

// Returns the temporary working directory.
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

fn fetch_package(package store.JsonPackage) !string {
  cache := cache_dir()

  os.mkdir_all(cache)!

  archive := os.join_path(cache, '${package.name}-${package.version}.simpkg')

  if !os.exists(archive) {
    println('downloading ${package.name}...')
    http.download_file(package.source, archive)!
  }

  return archive
}

fn cmd_install(name string) ! {
  mut db := store.open()!

  remote := db.get_remote(name)!

  archive := fetch_package(remote)!

  extract_dir, staging_dir := prepare_temp()!

  root := pkg.open(archive, extract_dir)!
  info := pkg.parse(root)!

  // Verify dependencies.
  fs.check_deps(info.deps)!

  for file in info.files {
    owner := db.owner(file)!

    if owner != '' && owner != info.name {
      return error('conflict: ${file} owned by ${owner}')
    }
  }

  println('installing ${info.name} ${info.version}')

  fs.install(info, &db, staging_dir)!

  db.register(info)!
}
