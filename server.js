'use strict'

const express = require('express')
const { version } = require('./package.json')

// Constants
const PORT = 8080
const HOST = '0.0.0.0'

// Fetch git sha
const gitsha = require('child_process')
  .execSync('git rev-parse --short HEAD')
  .toString().trim()

// App
const app = express()
app.get('/version', function (req, res) {
  const myJson = {}
  myJson.myapplication = [{ version: version, lastcommitsha: gitsha, description: 'pre-interview technical test' }]
  res.json(myJson)
})

app.listen(PORT, HOST)
console.log()
