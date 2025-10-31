project(
  'template-nuttx-apps',
  'c',
  version: run_command(find_program('bash'), './.version.sh', check: true).stdout().strip(),
  default_options: 'c_std=c17',
  meson_version: '>=0.63.0',
)
cc = meson.get_compiler('c')
isnuttx = cc.get_define('__NuttX__') != '' # Won't be defined outside NuttX

if not isnuttx
  add_project_arguments('-D_GNU_SOURCE', language: 'c')
endif
add_project_arguments('-DPROJECT_VERSION="@0@"'.format(meson.project_version()), language: 'c')


subdir('mpc')

