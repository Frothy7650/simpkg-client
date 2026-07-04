module main

import os

pub fn cmd_clear_cache() ! {
	if os.exists(temp_dir()) {
		os.rmdir_all(temp_dir())!
		println('removed ${temp_dir()}')
	}
	os.rmdir_all(cache_dir())!
	println('removed ${cache_dir()}')
}
