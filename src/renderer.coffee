{ipcRenderer} = require 'electron'
$container = document.querySelector '.container'

fillTemplate = (template, data) -> 
  template.replace /\{\{(.+?)\}\}/g, (all, match) ->
    evalInContext = (str, context) ->
      (new Function("with(this) {return #{str}}"))
      .call context
    evalInContext match, data
renderOptions = (options, val) ->
  html = ''
  for option in options
    html += '<option' + (if option is val then ' selected' else '') + '>' + option + '</option>'
  html
ipcRenderer.on 'render', (app, data) ->
  html = ''
  rowTemplate = '<div class="row{{newIntent?\' new\':\'\'}}"><div class="text">{{text}}</div><div class="select"><select>{{renderOptions(intents,intent)}}</select></div></div>'
  examples = data.merged.rasa_nlu_data.common_examples
  for example in examples
    html += fillTemplate rowTemplate,
      text: example.text
      intent: example.intent
      intents: data.mergedIntents
      newIntent: example.newIntent
      renderOptions: renderOptions
  $container.innerHTML = html
updateStatus = (data) ->
  $container.innerHTML = '<h1>Awaiting files</h1>'
  #$container.innerHTML += '<h3>CSV</h3>' if not data.csv
  $container.innerHTML += '<h3>JSON</h3>' if not data.json
  $container.innerHTML += '<p>Select files using the main menu</p>'
updateStatus {}
ipcRenderer.on 'updateStatus', (app, data) ->
  updateStatus data
ipcRenderer.on 'saveJson', (app) ->
  rows = document.querySelectorAll '.row'
  output = []
  for row in rows
    output.push
      text: row.querySelector('.text').innerText
      intent: row.querySelector('select').value
  ipcRenderer.send 'saveJson', output