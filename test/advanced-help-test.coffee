chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'advanced-help', ->
  before ->
    # Mock the robot
    @robot =
      name: 'bot'
      respond: sinon.spy()

    # Load hubot-advanced-help
    require('../src/advanced-help')(@robot)

    # Simulate receiving a message
    @say = ( msg ) ->

      # Iterate through all calls to robot.respond
      for [ regex, cb ] in @robot.respond.args

        # Find the first responder that matches the current message
        if matches = msg.match regex

          # Call respond callback with mocked response object
          send = sinon.spy()
          cb {
            send: send
            match: [ @robot.name, matches... ]
          }

          # Return the response message
          return send.args[0][0]

      # Could not find a matching responder
      return undefined

  it 'responds to bot help', ->
    response = @robot.name + ' help [query words or #tags]\n        get available commands\n'
    expect(@say('help')).to.equal(response)
    expect(@say('commands')).to.equal(response)

  it 'responds to bot examples', ->
    response = @robot.name + ' e.g. #dev #ops packer\n        search for examples tagged as both #dev and #ops and filtered to match "packer"\n'
    expect(@say('examples')).to.equal(response)
    expect(@say('e.g.')).to.equal(response)

  it 'responds to bot tags', ->
    response = '#help'
    expect(@say('tags')).to.equal(response)
