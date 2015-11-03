# Generated on 2015-10-20 using generator-bower 0.0.1
'use strict'

mountFolder = (connect, dir) ->
    connect.static require('path').resolve(dir)

module.exports = (grunt) ->
  require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks)

  yeomanConfig =
    src: 'src'
    dist : 'dist'

  grunt.initConfig
    yeoman: yeomanConfig

    browserify:
      dev:
        src:  "src/adequate-tabs.coffee"
        dest: "dist/adequate-tabs.js"
        options:
          debug: true
          transform: [ 'coffeeify' ]
          browserifyOptions:
            standalone: 'AdequateTabs'
            plugin: [ 'browserify-derequire' ]

    uglify:
      build:
        src: '<%=yeoman.dist %>/adequate-tabs.js'
        dest: '<%=yeoman.dist %>/adequate-tabs.min.js'

    mochaTest:
      test:
        options:
          reporter: 'spec'
          compilers: 'coffee:coffee-script'
        src: ['test/**/*.coffee']

    grunt.registerTask 'default', [
      #'mochaTest'
      'browserify'
      'uglify'
    ]
