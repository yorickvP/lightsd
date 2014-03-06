#!/usr/bin/env node


	// @list-schedule = list-schedule
	// @del-schedule = del-schedule
	// @add-schedule = add-schedule
	// @add-schedule-light = add-schedule-light

var airport = require('airport')
var server = require('./lib/server')
var air = airport('frumar.yori.cc', 9090)
var lights = air.connect('lightsd@0.1.0')
if (process.argv.length < 3) {
	console.log("no command given")
}
else {
	lights(function(r) {
		switch (process.argv[2]) {
			case "list":
				r.lights.list(function(l) {
					Object.keys(l).forEach(function(k) {
						process.stdout.write(l[k].name + " " + "\n")
					})
					process.exit()
				})
				break;
			case "list-schedule":
				r.schedule.list(function(l) {
					Object.keys(l).forEach(function(k) {
						process.stdout.write(l[k].desc + " " + "\n")
					})
					process.exit()
				})
				break;
			case "on":
			case "off":
				if (process.argv.length == 4) {
					r.lights.turn(process.argv[3], process.argv[2] == "on", cb)
				} else {
					r.turn(process.argv[3], process.argv[4], process.argv[2] == "on", cb)
				}
				function cb(st) {
					if (st) {
						process.stdout.write("OK")
					} else if (st === false) {
						process.stdout.write("ERR")
					}
					process.exit()
				}
				break;
			case "add":
				r.lights.add(process.argv[3], process.argv[4], process.argv[5], process.exit)
				break;
			case "del":
				r.lights.delName(process.argv[3], process.exit)
				break;
			case "web":
				server(r, +process.argv[3])
				break
			default:
				process.stderr.write("Error: unknown command")
				process.exit()
		}
	})
}
