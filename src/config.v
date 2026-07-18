module main

import toml
import os

const config_dir = os.join_path(os.config_dir()!, 'simpkg')
const config_file = os.join_path(config_dir, 'simpkg.toml')

pub struct Config {
pub:
	dag_url string
}

pub fn Config.new() !Config {
	mut cfg := Config{
		dag_url: $if windows {
			'https://simpkg.frothy7650.org/api/windows/dag'
		} $else $if linux {
			'https://simpkg.frothy7650.org/api/linux/dag'
		} $else {
			panic('No package list for this OS')
		}
	}

	if os.exists(config_file) && os.is_file(config_file) {
		cfg = toml.decode[Config](os.read_file(config_file)!)!
	}

	if cfg.dag_url.trim_space() == '' {
		panic('invalid config URL')
	}

	return cfg
}
