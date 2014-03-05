require! [suncalc]
times-for-day = require \../sun_sched.js
add-sched = ({add-light}, schedules) ->
	schedules.for-each ([name, state, desc, time]) ->
		add-light +time, name, state, desc
		console.log name, state, desc, time

rem-sched = ({list, del}, schedules, cb) ->
	descs = schedules.map (.2)
	scheds = list!
	for id, {desc} of scheds
		if desc in descs
			del id

export schedule-run = (sched-control, {time: date, desc}) ->
	# the closest solar transit to the given time is used
	# so set it to noon
	date = new Date(date)
	date.set-hours 12hr  0m  0s
	scheds = times-for-day date, (suncalc.get-times date, _, _)
	rem-sched sched-control, scheds
	add-sched sched-control, scheds
	schedule-future sched-control

date-repr = (d) ->
	[d.get-full-year!, d.get-month!, d.get-date!]*'-'

export schedule-future = ({list, add-sched, del}) ->
	date = new Date
	date.set-hours  0hr 1m 15s 10ms
	date.set-date   date.get-date! + 1
	if date < Date.now!
		console.warn "trying to trigger a schedule renewal in the past"
		return
	repr = 'future ' + date-repr date
	scheds = list!
	for id, {desc} of scheds
		if desc == repr
			del id
	add-sched date, repr
