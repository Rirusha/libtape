vapi_sources = files(
  'config.vapi',
)

vala_sources = files(
  'cachier/cachier.vala',
  'cachier/controller.vala',
  'cachier/humanity-size.vala',
  'cachier/info-db.vala',
  # 'cachier/job.vala',
  # 'cachier/jober.vala',
  'cachier/location.vala',
  'cachier/storager.vala',

  'player/mods/abstract-mode.vala',
  'player/mods/abstract-shufflable.vala',
  'player/mods/empty.vala',
  'player/mods/flow.vala',
  'player/mods/local.vala',
  'player/mods/track-list.vala',
  'player/mpris.vala',
  'player/player.vala',

  'ya-m-api/objects/account/about.vala',
  'ya-m-api/objects/additional-info/lyrics-major.vala',
  'ya-m-api/objects/additional-info/lyrics.vala',
  'ya-m-api/objects/additional-info/similar-tracks.vala',
  'ya-m-api/objects/album/album.vala',
  'ya-m-api/objects/album/label.vala',
  'ya-m-api/objects/artist/artist.vala',
  'ya-m-api/objects/artist/counts.vala',
  'ya-m-api/objects/artist/link.vala',
  'ya-m-api/objects/artist/ratings.vala',
  'ya-m-api/objects/cover.vala',
  'ya-m-api/objects/download-info.vala',
  'ya-m-api/objects/icon.vala',
  'ya-m-api/objects/library/all-ids.vala',
  'ya-m-api/objects/play.vala',
  'ya-m-api/objects/playlist/case-forms.vala',
  'ya-m-api/objects/playlist/liked-playlist.vala',
  'ya-m-api/objects/playlist/made-for.vala',
  'ya-m-api/objects/playlist/play-counter.vala',
  'ya-m-api/objects/playlist/playlist-absence.vala',
  'ya-m-api/objects/playlist/playlist-recommendations.vala',
  'ya-m-api/objects/playlist/playlist.vala',
  'ya-m-api/objects/playlist/user.vala',
  'ya-m-api/objects/plays.vala',
  'ya-m-api/objects/rotor/block.vala',
  'ya-m-api/objects/rotor/dashboard.vala',
  'ya-m-api/objects/rotor/event.vala',
  'ya-m-api/objects/rotor/feedback.vala',
  'ya-m-api/objects/rotor/id.vala',
  'ya-m-api/objects/rotor/queue.vala',
  'ya-m-api/objects/rotor/restrictions.vala',
  'ya-m-api/objects/rotor/seed.vala',
  'ya-m-api/objects/rotor/sequence.vala',
  'ya-m-api/objects/rotor/session-new.vala',
  'ya-m-api/objects/rotor/settings.vala',
  'ya-m-api/objects/rotor/station-info.vala',
  'ya-m-api/objects/rotor/station-tracks.vala',
  'ya-m-api/objects/rotor/station-tracks.vala',
  'ya-m-api/objects/rotor/station.vala',
  'ya-m-api/objects/rotor/track-parameters.vala',
  'ya-m-api/objects/rotor/value-heap.vala',
  'ya-m-api/objects/rotor/value.vala',
  'ya-m-api/objects/rotor/wave.vala',
  'ya-m-api/objects/track-heap.vala',
  'ya-m-api/objects/track-short.vala',
  'ya-m-api/objects/track/chart.vala',
  'ya-m-api/objects/track/lyrics-info.vala',
  'ya-m-api/objects/track/meta-data.vala',
  'ya-m-api/objects/track/track.vala',

  'ya-m-api/client.vala',
  'ya-m-api/difference-builder.vala',
  'ya-m-api/has-cover.vala',
  'ya-m-api/has-id.vala',
  'ya-m-api/has-tracks.vala',
  'ya-m-api/jsoner.vala',
  'ya-m-api/utils.vala',

  'client.vala',
  'likes-controller.vala',
  'settings.vala',
  'utils.vala',
  'ya-m-talker.vala',
)

sources = [
  vapi_sources,
  vala_sources,
]

lib = shared_library(
  lib_name,
  sources,
  dependencies: dependencies,
  include_directories: config_h_dir,
  vala_header: header_name,
  vala_vapi: vapi_name,
  vala_gir: gir_name,
  version: meson.project_version(),
  install: true,
  install_dir: [true, true, true, true],
)

lib_dep = declare_dependency(
  link_with: lib,
  include_directories: include_directories('.'),
  dependencies: dependencies
)

deps_conf = configuration_data()
deps_conf.set ('DEPS',  '\n'.join (deps_pkgs))

configure_file(
  input: 'lib.deps.in',
  output: deps_name,
  configuration: deps_conf,
  install: true,
  install_dir: get_option('datadir') / 'vala' / 'vapi',
)

if get_option('introspection')
  g_ir_compiler = find_program('g-ir-compiler')
  custom_target(
    'typelib',
    command: [
      g_ir_compiler,
      '--shared-library', '@PLAINNAME@',
      '--output', '@OUTPUT@',
      '--includedir', gee_girdir,
      meson.current_build_dir() / gir_name,
    ],
    input: lib,
    output: typelib_name,
    depends: lib,
    install: true,
    install_dir: get_option('libdir') / 'girepository-1.0',
  )
endif

pkgconfig.generate(
  lib,
  name: versioned_name,
  requires: pgconfig_dependencies,
  subdirs: [ versioned_name ],
  description: pkgc_description,
  version: meson.project_version(),
  url: pkgc_url,
)
