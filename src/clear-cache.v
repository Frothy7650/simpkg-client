module main

import os

pub fn cmd_clear_cache(target_root string) ! {
	if os.exists(temp_dir(target_root)) {
		os.rmdir_all(temp_dir(target_root))!
		println('removed ${temp_dir(target_root)}')
	}
	os.rmdir_all(cache_dir(target_root))!
	println('removed ${cache_dir(target_root)}')
}
