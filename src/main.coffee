'use strict'

{app, BrowserWindow, Menu, dialog, ipcMain} = require 'electron'
{autoUpdater} = require 'electron-updater'
url = require 'url'
path = require 'path'
fs = require 'fs-extra'
parse = require 'csv-parse'

data =
  csv: null
  json: null
  merged: null
  csvIntents: []
  jsonIntents: []
  mergedIntents: []

processData = ->
  data.merged = JSON.parse JSON.stringify data.json
  examples = data.merged.rasa_nlu_data.common_examples
  data.csvIntents = []
  data.jsonIntents = []
  data.mergedIntents = []
  for example in examples
    data.jsonIntents.push example.intent if data.jsonIntents.indexOf(example.intent) is -1
  data.mergedIntents = JSON.parse JSON.stringify data.jsonIntents
  for row, i in data.csv
    continue if not i
    examples.push
      text: row[2]
      intent: row[1]
      newIntent: data.jsonIntents.indexOf(row[1]) is -1
    if data.mergedIntents.indexOf(row[1]) is -1
      data.csvIntents.push row[1]
      data.mergedIntents.push row[1]
  mainWindow.webContents.send 'render', data
  
parseCsv = (csv) ->
  new Promise (resolve) ->
    output = []
    parse csv,
      trim: true
      skip_empty_lines: true
    .on 'readable', ->
      while record = this.read()
        output.push record
    .on 'end', ->
      resolve output
openCsv = ->
  results = dialog.showOpenDialog
    properties: ['openFile']
    filters: [
      name: 'CSV'
      extensions: ['csv']
    ]
  data.csv = await parseCsv await fs.readFile results[0], 'utf8' if results.length
  if data.csv and data.json
    processData()
  else
    mainWindow.webContents.send 'updateStatus', data
openJson = ->
  results = dialog.showOpenDialog
    properties: ['openFile']
    filters: [
      name: 'JSON'
      extensions: ['json']
    ]
  text = await fs.readFile results[0], 'utf8' if results.length
  text = text.substr text.indexOf('{')
  data.json = JSON.parse text
  if data.csv and data.json
    processData()
  else
    mainWindow.webContents.send 'updateStatus', data
saveJson = ->
  mainWindow.webContents.send 'saveJson'
ipcMain.on 'saveJson', (win, output) ->
  result = dialog.showSaveDialog
    filters: [
      name: 'JSON'
      extensions: ['json']
    ]
  if result
    mydata = 
      rasa_nlu_data:
        common_examples: output
    await fs.writeFile result, JSON.stringify(mydata, null, '  '), 'utf8'
    dialog.showMessageBox
      type: 'info'
      buttons: ['OK']
      message: 'File saved'
mainWindow = null
ready = ->
  autoUpdater.checkForUpdatesAndNotify()
  applicationMenu = Menu.buildFromTemplate [
    label: 'File'
    submenu: [
      label: 'Open Csv'
      click: openCsv
    ,
      label: 'Open Json'
      click: openJson
    ,
      label: 'Save Json'
      click: saveJson
    ,
      label: 'Quit'
      click: ->
        app.quit()
    ]
  ]
  Menu.setApplicationMenu applicationMenu
  mainWindow = new BrowserWindow
    width: 800
    height: 600
  mainWindow.on 'closed', ->
    mainWindow = null
  mainWindow.loadURL url.format
    pathname: path.join __dirname, 'index.html'
    protocol: 'file:'
    slashes: true
app.on 'ready', ready
app.on 'window-all-closed', ->
  process.platform is 'darwin' or app.quit()
app.on 'activiate', ->
  mainWindow or ready()