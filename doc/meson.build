valadoc = find_program('valadoc')

valadoc_vala_dir = 'libtape-1-vala'
valadoc_target = custom_target(
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
    config_vala,
    '--target-glib=' + glib_min_version,
    '--package-name=' + meson.project_name(),
    '--package-version=' + meson.project_version(),
    '--verbose',
    '--force',
    '-o', join_paths(meson.current_build_dir(), valadoc_vala_dir),
  ],

  build_by_default: true,
  output: valadoc_vala_dir,
  depends: libtape,
)

valadoc_c_dir = 'libtape-1'
cdoc_target = custom_target(
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
    config_vala,
    '--target-glib=' + glib_min_version,
    '--package-name=' + meson.project_name(),
    '--package-version=' + meson.project_version(),
    '--verbose',
    '--force',
    '-o', join_paths(meson.current_build_dir(), valadoc_c_dir),
    '--doclet-arg=' + 'lib/libtape-1.h',
    '--doclet=gtkdoc',
  ],

  build_by_default: true,
  output: valadoc_c_dir,
  depends: libtape,
)
