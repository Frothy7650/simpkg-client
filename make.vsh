#!/usr/bin/env -S v run

import build

const app_name = 'bin/simpkg'
const bin_dir = $if windows { local_bin_dir() } $else { '/usr/bin/' }
const sudo = $if windows { '' } $else { 'sudo' }

mut context := build.context(
	default: 'build'
)

context.task(
	name:    'build'
	run:     |self| system('v src/. -o ${app_name}')
)

context.task(
	name:    'build-prod'
	run:     |self| system('v -cc clang -prod src/. -o ${app_name}')
)

context.task(
	name: 'format'
	run:  |self| system('v fmt -w src/.')
)

context.task(
  name: 'install'
  depends: ['build']
  run:  |self| system('${sudo} cp ${app_name} ${bin_dir}')
)

context.run()
