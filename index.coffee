fs = require 'fs'
path = require 'path'

module.exports = (robot, scripts) ->
  if process.env.HUBOT_ADVANCED_HELP_DISABLE is 'true'
    return # Disable advanced help even if it is included in external-scripts.json

  scriptsPath = path.resolve(__dirname, 'src')
  if fs.existsSync scriptsPath
    for script in fs.readdirSync(scriptsPath).sort()
      if scripts? and '*' not in scripts
        robot.loadFile(scriptsPath, script) if script in scripts
      else
        robot.loadFile(scriptsPath, script)
