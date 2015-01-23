# Description:
#   Hubot [strk.io](http://strk.io) integration.
#
# Dependencies:
#   None
#
# Configuration:
#   STRKIO_API (http://api.strk.io by default)
#   STRKIO_ACCESS_TOKEN (required)
#   STRKIO_GIST (required)
#
# Commands:
#   hubot streak browse
#   hubot streak list
#   hubot streak "streak_name" [+-]?{number} # e.g. streak "keep_build_green" -1
#   hubot streak "streak_name" value # shows today's value
#
# Author:
#   Stanley Shyiko <stanley.shyiko@gmail.com>

http = require('http')

STRKIO = 'http://strk.io'
STRKIO_API = process.env.STRKIO_API || 'http://api.strk.io'
ACCESS_TOKEN = process.env.STRKIO_ACCESS_TOKEN
GIST = process.env.STRKIO_GIST

today = -> (new Date()).toISOString().substr(0, 10)

module.exports = (robot) ->
  failed = (err, res) ->
    err || res.statusCode >= 400

  explainFailure = (err, res) ->
    "Failed (#{if err then err.message else 'Gateway responded ' +
      res.statusCode + ' - ' + http.STATUS_CODES[res.statusCode]})"

  strkio = (url) ->
    robot.http("#{STRKIO_API}#{url}")
      .header('Authorization', "token #{ACCESS_TOKEN}")

  robot.respond /streak browse/, (msg) ->
    msg.reply "#{STRKIO}/?gist=#{GIST}"

  robot.respond /streak list/, (msg) ->
    strkio("/v1/gists/#{GIST}")
      .get() (err, res, body) ->
        return msg.reply explainFailure(err, res) if failed(err, res)
        msg.reply '"' + body.streaks.map((_) -> _.name).join('", "') + '"'

  robot.respond /streak "([^"]+)" ([+-]?\d+)/, (msg) ->
    data = {}
    data[today()] = msg.match[2]
    strkio("/v1/gists/#{GIST}/streaks/#{msg.match[1]}")
      .post(JSON.stringify({data: data})) (err, res) ->
        return msg.reply explainFailure(err, res) if failed(err, res)
        msg.reply 'Done'

  robot.respond /streak "([^"]+)" value/, (msg) ->
    strkio("/v1/gists/#{GIST}/files/#{msg.match[1]}")
      .get() (err, res, body) ->
        return msg.reply explainFailure(err, res) if failed(err, res)
        msg.reply(body.data[today()] ? 0)
