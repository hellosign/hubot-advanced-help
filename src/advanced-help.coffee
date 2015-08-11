# vim: ts=2 sw=2 expandtab
#
# Description:
#   A hubot help replacement that supports searching either commands
#   or examples via regular search strings and/or #hash #tags.
#
# Notes:
#   Saying only 'hubot help' will respond with a list of *only* untagged
#   commands, but suggest a list of available tags to lookup for additional
#   results. This is to reduce noise.
#
#   Saying 'hubot help query words #tag1 #tag2' will by default search
#   for all commands that match *all* of the tags and the given query words.
#   i.e. a longer query means less results. To invert this behavior (i.e.,
#   use "OR" instead of "AND" and get the union of all results), set
#   HUBOT_ADVANCED_HELP_LOGIC='OR' in your environment variables.
#
#   To use this module, simply include a 'Tags:' section in your documentation.
#   You can list tags either comma-separated or line-by-line.
#
#   Currently, this script currently cannot get documentation from external-scripts.
#   If the hubot folks accept a PR from me that makes scriptDocumentation accessible
#   off of the robot instance, then it will be able to and you can disregard this
#   note.
#
#   None of the environment variables necessarily need to be set, this script
#   has reasonable defaults set by... default.
#
# Configuration:
#   HUBOT_ADVANCED_HELP_LOGIC='OR|AND' -- defaults to "AND"
#   HUBOT_ADVANCED_HELP_SCRIPTS_PATH='/opt/hubot/scripts:/opt/hubot/scripts-available:/etc:/etc'
#
# Commands:
#   hubot help [query words or #tags] - get available commands
#   hubot e.g. [query words or #tags] - get command examples
#   hubot tags                        - get a list of all known #tags
#
# Examples:
#   hubot help #dev #ops packer - search for commands tagged as both #dev and #ops and filtered to match "packer"
#   hubot e.g. #dev #ops packer - search for examples tagged as both #dev and #ops and filtered to match "packer"
#
# Tags:
#   help
#
# Author:
#   Nour Sharabash <nour@hellosign.com>

Fs   = require 'fs'
Path = require 'path'

module.exports = ( robot ) ->

  if process.env.HUBOT_ADVANCED_HELP_SCRIPTS_PATH
    HUBOT_ADVANCED_HELP_SCRIPTS_PATH = process.env.HUBOT_ADVANCED_HELP_SCRIPTS_PATH.split /:/
  else
    HUBOT_ADVANCED_HELP_SCRIPTS_PATH = []

  if process.env.HUBOT_ADVANCED_HELP_LOGIC and process.env.HUBOT_ADVANCED_HELP_LOGIC == 'OR'
    HUBOT_ADVANCED_HELP_LOGIC = 'OR'
  else
    HUBOT_ADVANCED_HELP_LOGIC = 'AND'

  class Help
    constructor: () ->
      @tags     = {}
      @tagged   = { commands: [], examples: [] }
      @untagged = { commands: [], examples: [] }

      @scriptDocumentation = []
      @buildDocumentation()

      @buildTags()

      return

    buildDocumentation: () ->
      if robot.scriptDocumentation
        @scriptDocumentation = robot.scriptDocumentation.slice()
        return

      # load local scripts
      @loadPath Path.resolve '.', 'scripts'
      @loadPath Path.resolve '.', 'src', 'scripts'

      # load hubot-scripts
      hubotScripts = Path.resolve '.', 'hubot-scripts.json'
      if Fs.existsSync hubotScripts
        data = Fs.readFileSync hubotScripts
        if data.length > 0
          try
            scripts = JSON.parse data
            scriptsPath = Path.resolve 'node_modules', 'hubot-scripts', 'src', 'scripts'
            for script in scripts
              @loadFile scriptsPath, script

      # load this script
      @loadFile __dirname, Path.basename __filename

      for path in HUBOT_ADVANCED_HELP_SCRIPTS_PATH
        @loadPath path

    loadPath: ( path ) -> # borrowed from github/hubot/src/robot.coffee
      if Fs.existsSync path
        for file in Fs.readdirSync( path ).sort()
          @loadFile path, file

    loadFile: ( path, file ) -> # borrowed from github/hubot/src/robot.coffee
      ext  = Path.extname file
      full = Path.join path, Path.basename( file, ext )

      if require.extensions[ ext ]
        try
          @parseHelp Path.join path, file
        catch error
          console.error "Unable to load #{full}: #{error.stack}"
          process.exit( 1 )

    parseHelp: ( path ) -> # borrowed from github/hubot/src/robot.coffee
      scriptName          = Path.basename( path ).replace /\.(coffee|js)$/, ''
      scriptDocumentation = {}

      body = Fs.readFileSync path, 'utf-8'

      currentSection = null
      for line in body.split "\n"
        break unless line[0] is '#' or line.substr(0, 2) is '//'

        cleanedLine = line.replace(/^(#|\/\/)\s?/, "").trim()

        continue if cleanedLine.length is 0
        continue if cleanedLine.toLowerCase() is 'none'

        nextSection = cleanedLine.toLowerCase().replace(':', '')
        if cleanedLine.toLowerCase().match /^\w+:$/
          if nextSection in [ 'commands', 'examples', 'tags' ]
            currentSection = nextSection
            scriptDocumentation[currentSection] = []
          else
            currentSection = null
        else
          if currentSection
            scriptDocumentation[currentSection].push cleanedLine.trim()

      @scriptDocumentation.push scriptDocumentation

    buildTags: () ->
      _tagged   = { commands: {}, examples: {} }
      _untagged = { commands: {}, examples: {} }
      for docu in @scriptDocumentation
        if docu.tags is undefined
          if docu.commands
            for command in docu.commands
              if _untagged.commands[command] is undefined
                _untagged.commands[command] = true
                @untagged.commands.push command
          if docu.examples
            for example in docu.examples
              if _untagged.examples[example] is undefined
                _untagged.examples[example] = true
                @untagged.examples.push example
          continue

        if docu.examples isnt undefined
          for example in docu.examples
            if _tagged.examples[example] is undefined
              _tagged.examples[example] = true
              @tagged.examples.push example

        if docu.commands isnt undefined
          for command in docu.commands
            if _tagged.commands[command] is undefined
              _tagged.commands[command] = true
              @tagged.commands.push command

        docuTags = []
        for tagLine in docu.tags
          tags = tagLine.split( /[,\s]+/ )

          for tag in tags
            docuTags.push tag
            if not @tags[tag]
              @tags[tag] = { commands: [], examples: [], _commands: {}, _examples: {} }

        for tag in docuTags
          if docu.commands isnt undefined
            for command in docu.commands
              if @tags[tag]._commands[command] is undefined
                @tags[tag]._commands[command] = true
                @tags[tag].commands.push command

          if docu.examples isnt undefined
            for example in docu.examples
              if @tags[tag]._examples[example] is undefined
                @tags[tag]._examples[example] = true
                @tags[tag].examples.push example

      for tag, data of @tags
        delete @tags[tag]._commands
        delete @tags[tag]._examples

      return

  prefix = '' # try to blockquote to the best of our ability
  if robot.adapterName is 'hipchat'
    prefix = "/quote "

  help = null
  init_help = () ->
    if help is null
      help = new Help()

  get_results = ( search_string, result_type  ) ->

    result_type = if result_type is 'examples' then 'examples' else 'commands'

    # if just 'hubot help' or 'hubot examples' was ran, then return only
    # untagged results (to reduce noise). we'll also follow-up with a helpful
    # message saying "more results available via tags #a, #b, #c..."
    if not search_string
      results = help.untagged[ result_type ].slice()
      return results

    # otherwise we're dealing with either tags, query text, or both
    query = {
      tags: {}
      text: search_string
    }

    rx = /^.*((?:\s+#[^\s]+)|(?:^#[^\s]+)).*$/
    ( () ->
      matched         = query.text.match rx
      query.text      = query.text.replace( matched[1], '' ).trim()
      tag             = matched[1].trim().replace( /#/, '' )
      query.tags[tag] = true
    )() while rx.test query.text

    tags = Object.keys query.tags

    do_eeet = ( tags, operator ) ->
      # TODO: think about how to write this recursively so that we can
      # #tag OR #tag2 OR query AND #tag3 #tag4 #tag5
      # but that's overkill for now
      tag_results = {}
      all_results = {}
      return_set  = []

      for tag in tags
        tag_results[tag] = {}
        if help.tags[tag] and help.tags[tag][result_type]
          for result in help.tags[tag][result_type]
            tag_results[tag][result] = true

      if operator is 'AND' # intersection
        results = Object.keys tag_results[ tags[0] ]
        for result in results
          all_results[result] = true

        for tag in tags.slice( 1 )
          for result in results
            if all_results[result] and tag_results[tag][result] is undefined
              all_results[result] = false

        for result, bool of all_results
          if bool
            return_set.push result

      else # operator is 'or'
        for tag in tags
          results = Object.keys tag_results[tag]
          for result in results
            all_results[result] = true
        return_set = Object.keys all_results

      return return_set.sort()

    results = []

    if tags.length > 0 # we have either tags, or both tags and a query
      results = do_eeet tags, HUBOT_ADVANCED_HELP_LOGIC
    else # otherwise we definately at least have a query
      results = help.tagged[result_type].concat( help.untagged[result_type] )

    if query.text isnt ''
      results = results.filter ( result ) ->
        result.match new RegExp( query.text, 'i' )

    return results

  do_the_same_thing_but_for = ( result_type, search_string, res ) ->
    init_help()
    results = get_results( search_string, result_type ).map( ( result ) ->
      return result.replace /hubot/i, robot.name
    ).sort()

    if not search_string
      results = results.concat( [
        '-------------------------------------------------------------------------------'
      ] ).concat get_results( '#help', result_type ).map( ( result ) ->
        return result.replace /hubot/i, robot.name
      )

    available_tags = Object.keys help.tags

    if not search_string and available_tags.length > 0 # if just 'hubot help', then follow-up with a helpful message
      more = if results.length > 0 then 'more ' else ''
      sentence = "#{more}#{result_type} available for reference via the following hash-tags:\n#{ available_tags.sort().map( (val) -> return "##{val}" ).join( ', ' ) }"
      sentence = "#{sentence.substr(0,1).toUpperCase()}#{sentence.substr(1)}"
      results = results.concat( [ '', sentence ] )

    if results.length > 0
      res.send "#{prefix}#{results.join "\n"}"
    else if search_string
      res.send "#{prefix}No #{result_type} found for query '#{search_string}'."

  robot.respond /(?:help|commands)\s*(.*)?$/i, ( res ) ->
    do_the_same_thing_but_for 'commands', res.match[1], res
    #if not res.match[1]
    #  do_the_same_thing_but_for 'commands', '#help', res

  robot.respond /(?:examples|e.g.)\s*(.*)?$/i, ( res ) ->
    do_the_same_thing_but_for 'examples', res.match[1], res

  robot.respond /tags$/i, ( res ) ->
    init_help()
    available_tags = Object.keys help.tags
    res.send "#{ available_tags.sort().map( (val) -> return "##{val}" ).join( ', ' ) }"
