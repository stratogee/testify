UI.registerHelper 'withTestify', (value) ->
  if Session.get("showTestify") is true
    "withTestify"

UI.registerHelper 'includeTestify', (value) ->
  typeof Testify isnt "undefined"
