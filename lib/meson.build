vapi_sources = files(
  'config.vapi',
)

client_sources = files(
  'cachier/cachier.vala',
  'cachier/controller.vala',
  'cachier/humanity-size.vala',
  'cachier/info-db.vala',
  'cachier/job.vala',
  'cachier/jober.vala',
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

  'soup-wrapper/header.vala',
  'soup-wrapper/headers.vala',
  'soup-wrapper/post-content.vala',
  'soup-wrapper/soup-wrapper.vala',
  'ya-m-api/difference-builder.vala',
  'ya-m-api/has-cover.vala',
  'ya-m-api/has-id.vala',
  'ya-m-api/has-tracks.vala',

  'ya-m-api/objects/account/about.vala',
  'ya-m-api/objects/additional-info/lyrics-major.vala',
  'ya-m-api/objects/additional-info/lyrics.vala',
  'ya-m-api/objects/additional-info/similar-tracks.vala',
  'ya-m-api/objects/album/album.vala',
  'ya-m-api/objects/album/label.vala',
  'ya-m-api/objects/api-error.vala',
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
  'ya-m-api/objects/rotor/utils.vala',
  'ya-m-api/objects/rotor/value-heap.vala',
  'ya-m-api/objects/rotor/value.vala',
  'ya-m-api/objects/rotor/wave.vala',
  'ya-m-api/objects/track-heap.vala',
  'ya-m-api/objects/track-short.vala',
  'ya-m-api/objects/track/chart.vala',
  'ya-m-api/objects/track/lyrics-info.vala',
  'ya-m-api/objects/track/meta-data.vala',
  'ya-m-api/objects/track/track.vala',
  'ya-m-api/utils.vala',
  'ya-m-api/ya-m-client.vala',
  'ya-m-api/ya-m-object.vala',

  'client.vala',
  'jsoner.vala',
  'likes-controller.vala',
  'logger.vala',
  'settings.vala',
  'utils.vala',
  'ya-m-talker.vala',
)

libtape_sources = [
  vapi_sources,
  client_sources,
]

libtape_gi_name = 'Tape'
libtape_gi_version = '1'

libtape_gi = '@0@-@1@'.format(libtape_gi_name, libtape_gi_version)
libtape_gir = '@0@.gir'.format(libtape_gi)
libtape_typelib = '@0@.typelib'.format(libtape_gi)

include_dir = join_paths(get_option('prefix'), get_option('includedir'), meson.project_name())

libtape = shared_library(
  meson.project_name(),
  libtape_sources,
  dependencies: libtape_dependencies,
  vala_header: 'libtape.h',
  vala_vapi: 'libtape.vapi',
  vala_gir: libtape_gir,
  version: meson.project_version(),
  install: true,
  install_dir: [true, include_dir, true, true],
)

install_data(
  'libtape-1.deps',
  install_dir: join_paths(get_option('datadir'), 'vala', 'vapi'),
)

if get_option('introspection')
  g_ir_compiler = find_program('g-ir-compiler')
  custom_target(
    libtape_typelib,
    command: [
      g_ir_compiler,
      '--shared-library', '@PLAINNAME@',
      '--output', '@OUTPUT@',
      join_paths(meson.current_build_dir(), libtape_gir),
    ],
    input: libtape,
    output: libtape_typelib,
    depends: libtape,
    install: true,
    install_dir: join_paths(get_option('libdir'), 'girepository-1.0'),
  )
endif
