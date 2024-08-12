project(
  'libtape-1',
  ['c', 'vala'],
  version: '0.2.0',
  meson_version: '>= 0.62.0',
  license: 'GPL-3.0-only',
)

add_project_arguments(
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-include', 'config.h',
  language: ['c'],
)

glib_min_version = '2.76'
add_project_arguments(
  '--abi-stability',
  '--hide-internal',
  '--target-glib', glib_min_version,
  '--vapidir', meson.current_source_dir(),
  language: ['vala'],
)

pkgconfig = import('pkgconfig')
i18n = import('i18n')
gnome = import('gnome')

threads = dependency('threads')
libsoup = dependency('libsoup-3.0')
jsonglib = dependency('json-glib-1.0')
sqlite3 = dependency('sqlite3')
gee = dependency('gee-0.8')
libxml = dependency('libxml-2.0')
gstreamer = dependency('gstreamer-1.0')
gio = dependency('gio-2.0', version: '>= 2.72')

library_name = 'libtape'

conf = configuration_data()
conf.set_quoted('LIBRARY_NAME', library_name)
conf.set_quoted('APP_NAME', get_option('app_name'))
conf.set_quoted('APP_NAME_LOWER', get_option('app_name').to_lower())
conf.set_quoted('APP_ID', get_option('app_id'))
conf.set_quoted('G_LOG_DOMAIN', library_name)
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('DATADIR', join_paths(get_option('prefix'), get_option('datadir')))
conf.set_quoted('GNOMELOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))

libtape_dependencies = [
  threads,
  libsoup,
  jsonglib,
  sqlite3,
  gee,
  libxml,
  gstreamer,
  gio,
]

subdir('po')
subdir('lib')
subdir('tests')

if get_option('documentation')
  subdir('doc')
endif

gnome.post_install()
