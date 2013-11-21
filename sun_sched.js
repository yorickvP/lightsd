#!/usr/bin/env node
var SunCalc = require('suncalc')


//add-schedule-light = add-schedule-light
var airport = require('airport')
var air = airport('frumar.yori.cc', 9090)
var lights = air.connect('lightsd@0.0.2')

function startTime(d) {
	var times = SunCalc.getTimes(d, 52.22, 5.155)
	return times.sunsetStart }
function endTime(d) {
	var end = new Date(d)
	switch(d.getDay()) {
		case 0: case 1: case 2: case 3: case 4:
			end.setHours(23)
			end.setMinutes(15)
			break
		default:
			end.setDate(end.getDate() + 1)
			end.setHours(0)
			end.setMinutes(0)
			break }
	return end }
function dateRepr(d) {
	return [d.getFullYear(), d.getMonth(), d.getDate()].join("-") }

function addForDate(d, remote) {
	var start = startTime(d)
	var end   = endTime(d)
	var repr  = dateRepr(d)
	remote.schedule.addLight(+start, "schoorsteen", true, "sunset " + repr)
	remote.schedule.addLight(+end, "schoorsteen", false, "night " + repr)
	console.log("on: ", start)
	console.log("off: ", end)
}
function remForDate(d, remote, cb) {
	var repr  = dateRepr(d)
	remote.schedule.list(function(sched) {
		cb()
		Object.keys(sched).forEach(function(id) {
			if (sched[id].desc == "sunset " + repr ||
				sched[id].desc == "night "  + repr)
				remote.schedule.del(id) })})}

lights(function(r, conn) {
	var d = new Date
	// inputting a date before 00:40:41 gives times for previous day
	// so set it to noon
	d.setHours(12)
	d.setMinutes(0)
	d.setSeconds(0)
	remForDate(d, r, function() {
		addForDate(d, r)
		setTimeout(process.exit, 700)
	})
})

