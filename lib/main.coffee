# This program is suited only to manage your cozy installation from the inside
# Moreover app management works only for apps make by Cozy Cloud company.
# If you want a friendly application manager you should use the
# appmanager.coffee script.

require "colors"

program = require 'commander'
async = require "async"
fs = require "fs"
exec = require('child_process').exec

Client = require("request-json").JsonClient



program
  .version('1.0.4')
  .usage('<action> <app>')

program
    .command("replication <db> <source> <target> <continuous> <filters>")
    .description("Replication")
    .action (db, source, target, continuous, filters) ->
        data =
            "source": "http://localhost:#{source}/test_replicator"
            "target": "http://localhost:#{target}/test_replicator"
        if continuous is "true"
            data.continuous = true
        if filters is "true"
            data.filter = "myddoc/myfilter"
        console.log data
        console.log "Replication from #{source} to #{target}..."
        client = new Client ("http://localhost:#{db}/")
        client.post '_replicate', data, (err, res, body)  ->
            if err or body.error?
                console.log "Replication failed, Error : "
                console.log err if err?
                console.log body
            else if body.ok
                console.log body
                console.log "Replication is successfully finished"
            else
                console.log "Replication is finished but failed"

program
    .command("cancel_replication <db> <id>")
    .description("Cancel replication")
    .action (db, id) ->
        data =
            "id": id
            "cancel": true
        console.log "Cancel replication #{id}..."
        client = new Client ("http://localhost:#{db}/")
        client.post '_replicate', data, (err, res, body)  ->
            if err or body.error?
                console.log "Cancel failed, Error : "
                console.log err
                console.log body
            else
                console.log "Replication is canceled"

program
    .command("add_filter <db> <value>")
    .description("Add filter")
    .action (db, value) ->
        data =
            "_id": "_design/myddoc"
            "filters":
                "myfilter": "function (doc, req) {\n" +
                    "    if(doc._deleted) {\n" +
                    "        return true; \n" +
                    "    }\n" +
                    "    if (doc.type && doc.type === \"#{value}\") {\n" +
                    "        return true; \n"+
                    "    } else { \n" +
                    "        return false; \n" +
                    "    }\n" +
                    "}"
        console.log "Add filter with value #{value}..."
        client = new Client ("http://localhost:#{db}/")
        client.post 'test_replicator', data, (err, res, body)  ->
            if err or body.error?
                console.log "Add failed, Error : "
                console.log err
                console.log body
            else
                console.log "Filter is added"

program
    .command("change_filter <db> <value>")
    .description("Add filter")
    .action (db, value) ->
        data =
            "_id": "_design/myddoc"
            "filters":
                "myfilter": "function (doc, req) {\n" +
                    "    if(doc._deleted) {\n" +
                    "        return true; \n" +
                    "    }\n" +
                    "    if (doc.type && doc.type === \"#{value}\") {\n" +
                    "        return true; \n"+
                    "    } else { \n" +
                    "        return false; \n" +
                    "    }\n" +
                    "}"
        client = new Client ("http://localhost:#{db}/")
        client.del "test_replicator/#{data._id}", (err, res, body)  ->
            console.log body
            console.log "Add filter with value #{value}..."
            client.post 'test_replicator', data, (err, res, body)  ->
                if err or body.error?
                    console.log "Add failed, Error : "
                    console.log err
                    console.log body
                else
                    console.log "Filter is added"


program
    .command("replication_with_authentication <db> <source> <target> <continuous> <filters> <username1> <password1> <username2> <password2>")
    .description("Replication")
    .action (db, source, target, continuous, filters, username1, password1, username2, password2) ->
        console.log "Replication with authentication from #{source} to #{target}..."
        if continuous is "true"
            data.continuous = true
        if filters is "true"
            data.filter = "myddoc/myfilter"
        client = new Client ("http://localhost:#{db}/")
        client.setBasicAuth username1, password1

        # Initialize creadentials for backup
        credentials = "#{username1}:#{password1}"
        basicCredentials = new Buffer(credentials).toString('base64')
        authSource = "Basic #{basicCredentials}"
        # Initialize creadentials for cozy database
        credentials = "#{username2}:#{password2}"
        basicCredentials = new Buffer(credentials).toString('base64')
        authTarget = "Basic #{basicCredentials}"
        data =
            source:
                url : "http://localhost:#{source}/test_replicator"
                headers:
                    Authorization: authSource
            target:
                url: "http://localhost:#{target}/test_replicator"
                headers:
                    Authorization: authTarget
        console.log data
        client.post '_replicate', data, (err, res, body)  ->
            if err or body.error?
                console.log "Replication failed, Error : "
                console.log err if err?
                console.log body
            else if body.ok
                console.log body
                console.log "Replication is successfully finished"
            else
                console.log "Replication is finished but failed"


program
    .command("*")
    .description("Display error message for an unknown command.")
    .action ->
        console.log 'Unknown command, run "test_replicator --help"' + \
                    ' to know the list of available commands.'

program.parse process.argv
