Router.map ->
  @route 'testify',
    path: '/testify'

@assert = chai.assert

class Testify
  @helpers: {}
  @tests: {}
  @scenarios: {}
  @settings: {}

  @registerHelpers: (category, helpers) ->
    @helpers[category] ?= {}
    _.extend @helpers[category], helpers

  @registerTests: (category, tests) ->
    @tests[category] ?= {}
    _.extend @tests[category], tests

  @registerScenarios: (scenarios) ->
    _.extend @scenarios, scenarios

  @setup: ->
    chai.should()
    mocha.setup 'bdd'
    $("#mocha-stats").remove()

  @runAllScenarios: ->
    @setup()
    $("#mocha").html('')
    mocha.suite.suites = []
    mocha.suite.tests = []
    helpers = @helpers
    scenarios = @scenarios
    tests = @tests

    _.each _.keys(scenarios), (flow) ->
      describe flow, ->
        before (done) ->
          Meteor.call "testifyTeardown", (error, result) ->
            done()
        _.each scenarios[flow], (testPath) ->
          it testPath[1], (done) ->
            tests[testPath[0]][testPath[1]](done, helpers)

    mocha.run()

  @runScenario: (scenario) ->
    console.log scenario 
    @setup()
    $("#mocha").html('')
    mocha.suite.suites = []
    mocha.suite.tests = []
    helpers = @helpers
    scenarios = @scenarios
    tests = @tests

    describe scenario, ->
      _.each scenarios[scenario], (testPath) ->
        if Session.get("testify:#{scenario}:#{testPath[0]}:#{testPath[1]}") isnt true
          it testPath[1], (done) ->
            tests[testPath[0]][testPath[1]](done, helpers)
    mocha.run()

  @runTest: (category, test) ->
    @setup()
    # $("#mocha").html('')
    mocha.suite.suites = []
    mocha.suite.tests = []
    helpers = @helpers
    tests = @tests

    # describe category, ->
      # before (done) ->
      #   Meteor.call "testifyTeardown", (error, result) ->
      #     done()
    it test, (done) ->
      tests[category][test](done, helpers)

    mocha.run()

  @runScenarioTest: (category, test) ->
    @setup()
    mocha.suite.suites = []
    mocha.suite.tests = []
    helpers = @helpers
    tests = @tests

    # describe category, ->
      # before (done) ->
      #   Meteor.call "testifyTeardown", (error, result) ->
      #     done()
    it test, (done) ->
      tests[category][test](done, helpers)

    mocha.run()

  @clearAll: ->
    mocha.suite.suites = []
    mocha.suite.tests = []
    Meteor.call "testifyTeardown", (error, result) ->
      $("#mocha-stats").remove()
      $("#mocha").html('')


@Testify = Testify

Template.testify.helpers
  testCategories: -> _.pairs Testify.tests
  scenarios: -> _.pairs Testify.scenarios
  showTestify: -> Session.get("showTestify") is true
  testifyClass: -> 
    if Session.get("showTestify") is true
      "visible"
    else
      "hidden"

Template.testifyTestCategory.helpers
  name: -> @[0]
  tests: -> _.pairs @[1]

Template.testifyTest.helpers
  name: -> @test[0]
  code: -> @test[1]

Template.testify.events
  "click .testifyLink": (event, template) ->
    Session.set "showTestify", !Session.get("showTestify")
  "click a.runAll": (event, template) ->
    Testify.runAllScenarios()
  "click a.clearAll": (event, template) ->
    Testify.clearAll()


Template.testify.rendered = ->
  $(document).keyup (event) ->
    if event.keyCode is 192
      Session.set "showTestify", !Session.get("showTestify")

Template.testifyTest.events
  "click a.view": (event, template) ->
    $(template.find "pre").slideToggle()
  "click a.run": (event, template) ->
    Testify.runTest @category[0], @test[0]

Template.testifyScenario.helpers
  name: -> @[0]
  tests: -> @[1]

Template.testifyScenarioTest.helpers
  category: -> @test[0]
  name: -> @test[1]
  isChecked: ->
    Session.get("testify:#{@scenario[0]}:#{@test[0]}:#{@test[1]}") isnt true

Template.testifyScenario.events
  "click a.view": (event, template) ->
    $(template.find "ul").slideToggle()
  "click a.check": (event, template) ->
    category = @[0]
    selectedCount = _.filter(@[1], (item) -> Session.get "testify:#{category}:#{item[0]}:#{item[1]}").length
    newValue = selectedCount > (@[1].length / 2)
    _.each @[1], (item) ->
      Session.set "testify:#{category}:#{item[0]}:#{item[1]}", !newValue
  "click a.runScenario": (event, template) ->
    Testify.runScenario @[0]


Template.testifyScenarioTest.events
  "click input": (event, template) ->
    name = "testify:#{@scenario[0]}:#{@test[0]}:#{@test[1]}"
    Session.set name, !Session.get(name)
  "click a.runIndividual": (event, template) ->
    Testify.runScenarioTest @test[0], @test[1]

