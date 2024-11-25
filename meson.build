project(
  'libtape',
  ['c', 'vala'],
  version: '0.2.1',
  meson_version: '>= 1.0.0',
  license: 'GPL-3.0-or-later',
)

api_version = '0.2'
glib_min_version = '2.76'

lib_name = 'tape'
gir_name = 'Tape'

pkgc_description = 'Unofficial Yandex Music client library'
pkgc_url = 'https://gitlab.gnome.org/Rirusha/libtape'

versioned_name = meson.project_name() + '-' + api_version
versioned_gir_name = gir_name + '-' + api_version

deps_name = versioned_name + '.deps'
header_name = meson.project_name() + '.h'
vapi_name = versioned_name + '.vapi'
gir_name = versioned_gir_name + '.gir'
typelib_name = versioned_gir_name + '.typelib'

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
  'gio-2.0',
]

libsoup_dep = dependency('libsoup-3.0')
json_glib_dep = dependency('json-glib-1.0')
sqlite3_dep = dependency('sqlite3')
gee_dep = dependency('gee-0.8')
libxml_dep = dependency('libxml-2.0')
gstreamer_dep = dependency('gstreamer-1.0')
gio_dep = dependency('gio-2.0')
libapi_base_dep = dependency('libapi-base-1', fallback : ['libapi-base', 'libapi_base_dep'])
libyandex_music_api_dep = dependency('libyandex-music-api-0.1', fallback : ['libyandex-music-api', 'lib_dep'])

pgconfig_dependencies = [
  libsoup_dep,
  json_glib_dep,
  sqlite3_dep,
  gee_dep,
  libxml_dep,
  gstreamer_dep,
  gio_dep,
]
dependencies = pgconfig_dependencies + [
  libapi_base_dep,
  libyandex_music_api_dep
]

if libapi_base_dep.type_name() == 'pkgconfig'
  pgconfig_dependencies += libapi_base_dep
endif
if libyandex_music_api_dep.type_name() == 'pkgconfig'
  pgconfig_dependencies += libyandex_music_api_dep
endif

gee_girdir = gee_dep.get_variable('datadir') / 'gir-1.0'

add_project_arguments(
  '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
  '-include', 'config.h',
  language: ['c'],
)

add_project_arguments(
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
conf.set_quoted('DATADIR', get_option('prefix') / get_option('datadir'))
conf.set_quoted('GNOMELOCALEDIR', get_option('prefix') / get_option('localedir'))
conf.set10('CAN_CONTROL', get_option('can_control'))
conf.set10('CAN_QUIT', get_option('can_quit'))
conf.set10('CAN_RAISE', get_option('can_raise'))
conf.set10('CAN_SET_FULLSCREEN', get_option('can_set_fullscreen'))

configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

subdir('po')
subdir('lib')
subdir('tests')

if get_option('documentation')
  subdir('doc')
endif

gnome.post_install()
