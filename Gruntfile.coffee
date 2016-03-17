module.exports = (grunt) ->
  'use strict'

  # Load all grunt tasks matching the `grunt-*` pattern
  require('load-grunt-tasks')(grunt)

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    clean:
      public:
        src: 'public/*'

    coffee:
      compile:
        expand: yes
        cwd: 'src/'
        src: ['*.coffee', '**/*.coffee']
        dest: 'public/src/'
        ext: '.js'
      # For Mocha tests in browser.
      test:
        expand: yes
        cwd: 'test/'
        src: ['*.coffee', '**/*.coffee']
        dest: 'public/src/test'
        ext: '.js'


    handlebars:
      compile_test:
        options:
          amd: yes
          namespace: 'Handlebars'
          processName: (file) ->
            file.replace('.hbs', '')
                .replace('test/templates/', '')
        files:
          'public/src/test/templates.js': [
            'test/templates/**/*.hbs'
          ]
      compile:
        options:
          amd: yes
          namespace: 'Handlebars'
          processName: (file) ->
            file.replace('src/templates/', '')
                .replace('.hbs', '')
        files:
          'public/src/templates.js': [
            'src/templates/**/*.hbs'
          ]

    copy:
      test:
        src: [
          'test/index.html'
          'vendor/**/mocha.css'
          'node_modules/grunt-blanket-mocha/**/support/*.js'
        ]
        dest: 'public/'
      assets:
        files: [
          # Vendor source files.
          src: [
            'vendor/**/*.js'
            '!vendor/**/{doc,example,lang,test}*/**'
          ]
          dest: 'public/'
        ]

    blanket_mocha:
      options:
        threshold : 50
        globalThreshold : 65
        log : yes
        logErrors: yes
        moduleThreshold : 60
        modulePattern : './src/(.*?)/'
      ci:
        src: 'public/test/index.html'
        dest: 'test-results.xml'
        options:
          reporter: 'XUnit'
      test:
        src: 'public/test/index.html'

    'citare-scriptum':
      options:
        out: 'public/docs/'
        'repository-url': 'https://github.com/lookout/gringotts'
      coffee: ['src/**/*.coffee', '*.md']

    'gh-pages':
      docs:
        options:
          base: 'public/docs'
        src: ['**']
      release:
        options:
          base: 'public/src'
          branch: 'release'
          message: 'Release v<%= pkg.version %>'
          tag: 'v<%= pkg.version %>'
        src: [
          '**/*.js*'
          '!test/**'
        ]

    bump:
      options:
        # Tag will be created via gh-pages:release
        createTag: no
        commitFiles: '<%= bump.options.files %>'
        files: ['package.json', 'bower.json']
        pushTo: 'origin'
        updateConfigs: ['pkg']

    coffeelint:
      source: ['{src,test}/**/*.coffee', 'Gruntfile.coffee']
      options:
        configFile: 'coffeelint.json'

    htmlhint:
      options:
        htmlhintrc: '.htmlhintrc'
      html:
        src: ['src/templates/**/*.hbs', 'test/templates/**/*.hbs']

    shell:
      options:
        failOnError: yes
        stderr: yes
        stdout: yes
      specs:
        command: 'find test -regex ".*-test\.coffee" > public/testSpecs.txt'
      # Keep copy task clean.
      release:
        command: 'cp bower.json public/src/'
      localBuild:
        command: ->
          buildPath = grunt.option 'target'
          return '' unless buildPath
          "rm -r #{buildPath};" +
          "cp -R -v public/src #{buildPath};"

    concurrent:
      pipe:
        tasks: ['server', 'watch']
        options:
          logConcurrentOutput: yes

    server:
      options:
        host: '127.0.0.1'
        index: 'test/index.html'
        port: 8000

      release:
        options:
          prefix: 'public/'

    # Only run tasks on modified files.
    watch:
      options:
        spawn: no
        interrupt: yes
        dateFormat: (time) ->
          grunt.log
            .writeln("Compiled in #{time}ms @ #{(new Date).toString()} 💪\n")

      coffee_hbs:
        files: ['{src,test}/**/*.coffee', 'src/templates/**/*.hbs']
        tasks: [
          'newer:handlebars'
          'newer:coffee'
          'coffeelint'
          'blanket_mocha:test'
          'shell:localBuild'
        ]

      lint:
        files: 'Gruntfile.coffee'
        tasks: 'coffeelint'

      test:
        files: 'test/index.html'
        tasks: 'copy:test'

  # Create aliased tasks.
  grunt.registerTask 'default', ['build', 'lint', 'test', 'concurrent']
  grunt.registerTask 'docs', ['citare-scriptum', 'gh-pages:docs']
  grunt.registerTask 'test', ['blanket_mocha:test']
  grunt.registerTask 'test:ci', [
    'compile'
    'copy'
    'lint'
    'blanket_mocha:ci'
  ]

  grunt.registerTask 'release', 'Create release branch', (version='') ->
    version = ":#{version}" if version
    grunt.task.run [
      "bump-only#{version}"
      'shell:release'
      'gh-pages:release'
      'bump-commit'
    ]

  grunt.registerTask 'compile', [
    'handlebars'
    'coffee'
    'shell:specs'
  ]

  grunt.registerTask 'lint', [
    'coffeelint'
    'htmlhint'
  ]

  grunt.registerTask 'build', [
    'clean'
    'citare-scriptum'
    'compile'
    'copy'
  ]

  ###*
   * Useful to locally test changes you make to Gringotts within the app.
   * Recursively overwrites anything in the passed in path.
   * @param  {string} path - Relative pathname of where Gringotts fits
   *                         within your app
  ###
  grunt.registerTask 'release-local',
    'Release a local build of Gringotts to a given path',
    (path) ->
      buildPath = grunt.option 'target'
      if buildPath
        grunt.log.writeln "Building gringotts into #{buildPath}..."
        grunt.task.run(['build', 'shell:localBuild', 'watch'])
      else
        grunt.log.writeln(
          'Target parameter (i.e. --target="...") is required'
        )