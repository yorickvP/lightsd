require! [airport, \./lock]
require! MicroDB: \nodejs-microdb
air = airport \frumar.yori.cc 9090

air !(remote, conn) ->
	@turn = turn
	@list-lights = list-lights
	@del-light = del-light
	@del-light-by-name = del-light-by-name
	@add-light = add-light
	@turn-light = turn-light
	@list-schedule = list-schedule
	@del-schedule = del-schedule
	@add-schedule = add-schedule
	@add-schedule-light = add-schedule-light
.listen \lightsd@0.0.1

{spawn} = require \child_process


turn-lock = new lock
turn = (group, num, state) ->
	if typeof state is \boolean
		state = if state then \on else \off
	turn-lock.get ->
		console.log "Turning #state #group #num"
		proc = spawn \./kaku [group, num, state]
		proc.stdout.pipe(process.stdout)
		proc.on \exit turn-lock~free


lights-db = new Micro-DB do
	file: \lights.db

list-lights = (cb) -> cb lights-db.data
del-light = lights-db~del
del-light-by-name = (name) ->
	lights-db.del (lights-db.find \name name)
add-light = (name, group, num) ->
	lights-db.add {name, group, num}
turn-light = (name, state, cb) ->
	id = lights-db.find \name name
	if !id
		cb? false
	else
		{group, num} = lights-db.data[id]
		turn group, num, state
		cb? true

schedule-db = new Micro-DB do
	file: \schedule.db
list-schedule = (cb) -> cb schedule-db.data
del-schedule = ->
	schedule-db.del ...
	exec-schedule!
add-schedule = (+time, group, num, state, desc = '') ->
	schedule-db.add {time, group, num, state, desc}
	exec-schedule!
add-schedule-light = (+time, name, state, desc = '') ->
	schedule-db.add {time, name, state, desc}
	exec-schedule!

schedule-run = (s) ->
	if s.name?
		turn-light s.name, s.state
	else
		turn s.group, s.num, s.state	

schedule-next = ->
	min-s = void
	min-id = void
	for id,s of schedule-db.data
		if !min-s? || min-s.time > s.time
			min-s  = s
			min-id = id
	[min-id, min-s]

schedule-timeout = void
exec-schedule = ->
	if schedule-timeout?
		clear-timeout schedule-timeout
		schedule-timeout = void

	[id, s] = schedule-next!
	if !s?
		console.log "Nothing scheduled"
		return
	now = Date.now!

	if s.time < now
		console.log "executing something"
		process.next-tick -> schedule-run s
		schedule-db.del id
		exec-schedule!
	else
		console.log "Scheduling into the future"
		schedule-timeout = set-timeout exec-schedule, (s.time - now + 100)

process.on \SIGINT !->
	lights-db.flush!
	schedule-db.flush!
	process.exit!

exec-schedule!
