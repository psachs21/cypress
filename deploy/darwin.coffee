fs      = require("fs-extra")
cp      = require("child_process")
path    = require("path")
sign    = require("electron-osx-sign")
plist   = require("plist")
Promise = require("bluebird")
meta    = require("./meta")
Base    = require("./base")

sign  = Promise.promisify(sign)
fs    = Promise.promisifyAll(fs)

class Darwin extends Base
  buildPathToApp: ->
    path.join @buildPathToAppFolder(), "Cypress.app"

  buildPathToAppExecutable: ->
    path.join @buildPathToApp(), "Contents", "MacOS", "Cypress"

  buildPathToAppResources: ->
    path.join @buildPathToApp(), "Contents", "Resources", "app"

  runSmokeTest: ->
    @_runSmokeTest()

  runProjectTest: ->
    @_runProjectTest()

  getBuildDest: (pathToBuild, platform) ->
    ## returns ./build/darwin
    path.join path.dirname(pathToBuild), platform

  afterBuild: (pathToBuild) ->
    @log("#afterBuild")

    @modifyPlist(pathToBuild)

  modifyPlist: (pathToBuild) ->
    pathToPlist = path.join(pathToBuild, "Cypress.app", "Contents", "Info.plist")

    fs.readFileAsync(pathToPlist, "utf8").then (contents) ->
      obj = plist.parse(contents)
      obj.LSUIElement = 1
      fs.writeFileAsync(pathToPlist, plist.build(obj))

  codeSign: ->
    @log("#codeSign")

    sign({
      app: @buildPathToApp()
      platform: "darwin"
      verbose: true
    })

  verifyAppCanOpen: ->
    @log("#verifyAppCanOpen")

    new Promise (resolve, reject) =>
      sp = cp.spawn "spctl", ["-a", "-vvvv", @buildPathToApp()], {stdio: "inherit"}
      sp.on "exit", (code) ->
        if code is 0
          resolve()
        else
          reject new Error("Verifying App via GateKeeper failed")

  deploy: ->
    @build()
    .return(@)

module.exports = Darwin