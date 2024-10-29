project(
  'libtape',
  ['c', 'vala'],
  version: '0.2.1',
  meson_version: '>= 1.0.0',
  license: 'GPL-3.0-or-later',
)

api_version = '0.2'
versioned_name = meson.project_name() + '-' + api_version
gir_name = 'Tape'
versioned_gir_name = gir_name + '-' + api_version
glib_min_version = '2.76'

pkgconfig = import('pkgconfig')
i18n = import('i18n')
gnome = import('gnome')

deps_pkgs = [
  'libsoup-3.0',
  'json-glib-1.0',
  'sqlite3',
  'gee-0.8',
  'libxml-2.0',
  'gstreamer-1.0',
  'gio-2.0'
]

libtape_dependencies = []

foreach deps_pkg : deps_pkgs 
  libtape_dependencies += dependency(deps_pkg)
endforeach

gee = dependency(gio_pkg, version: '>= 2.72')
gee_girdir = gee.get_variable('datadir') / 'gir-1.0'
gee_vapidir = gee.get_variable('datadir') / 'vala' / 'vapi'

add_project_arguments(
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-include', 'config.h',
  language: ['c'],
)

add_project_arguments(
  '-enable-experimental-non-null',
  '--abi-stability',
  '--hide-internal',
  '--target-glib', glib_min_version,
  '--vapidir', meson.current_source_dir(),
  language: ['vala'],
)

conf = configuration_data()
conf.set_quoted('LIBRARY_NAME', gir_name)
conf.set_quoted('APP_NAME', get_option('app_name'))
conf.set_quoted('APP_NAME_LOWER', get_option('app_name').to_lower())
conf.set_quoted('APP_ID', get_option('app_id'))
conf.set_quoted('G_LOG_DOMAIN', gir_name)
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('DATADIR', join_paths(get_option('prefix'), get_option('datadir')))
conf.set_quoted('GNOMELOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))

configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

subdir('po')
subdir('lib')
subdir('tests')

if get_option('documentation')
  subdir('doc')
endif

gnome.post_install()
