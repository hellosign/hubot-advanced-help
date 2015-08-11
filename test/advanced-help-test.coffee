chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'advanced-help', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/advanced-help')(@robot)

  it 'responds to hubot help', ->
    expect(@robot.respond).to.have.been.calledWith(/help/)

  it 'responds to hubot e.g.', ->
    expect(@robot.respond).to.have.been.calledWith(/e.g./)

  it 'responds to hubot tags', ->
    expect(@robot.respond).to.have.been.calledWith(/tags/)

