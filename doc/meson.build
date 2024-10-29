valadoc = find_program('valadoc')

valadoc_vala_dir = versioned_name + '-vala'
custom_target(
  'valadoc',
  command: [
    valadoc,
    '--pkg=gee-0.8',
    '--pkg=gio-2.0',
    '--pkg=libsoup-3.0',
    '--pkg=json-glib-1.0',
    '--pkg=sqlite3',
    '--pkg=libxml-2.0',
    '--pkg=gstreamer-1.0',
    libtape_sources,
    '--target-glib=' + glib_min_version,
    '--package-name=' + meson.project_name(),
    '--package-version=' + meson.project_version(),
    '--verbose',
    '--force',
    '-o', meson.current_build_dir() / valadoc_vala_dir,
  ],

  build_by_default: true,
  input : libtape_sources,
  output: valadoc_vala_dir,
  depends: libtape,
)

custom_target(
  'cdocs',
  command: [
    valadoc,
    '--pkg=gee-0.8',
    '--pkg=gio-2.0',
    '--pkg=libsoup-3.0',
    '--pkg=json-glib-1.0',
    '--pkg=sqlite3',
    '--pkg=libxml-2.0',
    '--pkg=gstreamer-1.0',
    libtape_sources,
    '--target-glib=' + glib_min_version,
    '--package-name=' + meson.project_name(),
    '--package-version=' + meson.project_version(),
    '--verbose',
    '--force',
    '-o', meson.current_build_dir() / versioned_name,
    '--doclet-arg=lib/' + versioned_name + '.h',
    '--doclet=gtkdoc',
  ],

  build_by_default: true,
  output: versioned_name,
  depends: libtape,
)
