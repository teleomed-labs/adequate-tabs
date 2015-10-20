chai = require 'chai'
sinon = require 'sinon'

{ AdequateTabs } = require '../src/adequate-tabs'

chai.should()

describe 'adequate-tabs', ->
  it 'should say hello', ->
    at = new AdequateTabs
    at.greeting().should.equal 'Hello World'
