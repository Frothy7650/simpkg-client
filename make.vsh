#!/usr/bin/env -S v run

import build

const app_name = 'bin/simpkg'

mut context := build.context(
	default: 'build'
)

context.task(
	name:    'build'
	run:     |self| system('v src/. -o ${app_name}')
)

context.task(
	name:    'build-windows'
	run:     |self| system('v -os windows src/. -o ${app_name}')
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
  name: 'pkgtest'
  run:  |self| system('cd pkgtest/ && zip -r ../pkgtest.simpkg .')
)

context.task(
  name: 'install'
  run:  |self| system('sudo cp -r ${app_name} /usr/bin/simpkg')
  )

context.run()
