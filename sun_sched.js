#!/usr/bin/env node
var SunCalc = require('suncalc')


//add-schedule-light = add-schedule-light
var airport = require('airport')
var air = airport('frumar.yori.cc', 9090)
var lights = air.connect('lightsd@0.0.2')

function addForDate(d, remote) {
	var times = SunCalc.getTimes(d, 52.22, 5.155)
	var end = new Date(d)
	end.setDate(end.getDate() + 1)
	end.setHours(0)
	end.setMinutes(0)
	remote.schedule.addLight(+times.sunsetStart, "schoorsteen", true, "sunset")
	remote.schedule.addLight(+end, "schoorsteen", false, "night")
	console.log("on: ", times.sunsetStart)
	console.log("off: ", end)
}

lights(function(r) {
	addForDate(new Date, r)
	setTimeout(process.exit, 1000)
})

