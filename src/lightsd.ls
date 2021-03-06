require! [airport, \./lock]
require! MicroDB: \nodejs-microdb
{spawn} = require \child_process
settings = require \./config

sun_sched = require \./sun_sched

{version} = require "#__dirname/../package.json"

# spit :: IO ()
spit = -> process.stdout.write (new Date).toISOString() + ": #it\n"
# cbify :: (a -> b) -> (a -> (b -> ()) -> ())
cbify = (f) ->
	->
		if arguments.length == f.length + 1
			[...args, cb] = arguments
			ret = f ...
			cb? ret
		else
			f ...

air = airport settings.host, settings.port
air !(remote, conn) ->
	@turn =        cbify turn
	@lights =
		list:      cbify list-lights
		del:       cbify del-light
		del-name:  cbify del-light-by-name
		add:       cbify add-light
		turn:      cbify turn-light
	@schedule =
		list:      cbify list-schedule
		del:       cbify del-schedule
		add:       cbify add-schedule
		add-light: cbify add-schedule-light
.listen \lightsd@ + version


turn-lock = new lock
# turn :: Group -> Num -> Boolean -> IO ()
turn = (group, num, state) !->
	if typeof state is \boolean
		state = if state then \on else \off
	turn-lock.get ->
		spit "light #state #group #num"
		proc = spawn settings.controller, [group, num, state]
		proc.stdout.pipe(process.stdout)
		proc.on \exit turn-lock~free


lights-db = new Micro-DB do
	file: \lights.db

# list-lights :: Object Id, Object LightEntry
list-lights = -> lights-db.data
# del-light :: Id -> DBMod
del-light = lights-db~del

# del-light-by-name :: Name -> IO ()
del-light-by-name = (name) ->
	lights-db.del (lights-db.find \name name)
# add-light :: String -> Group -> Num -> DBMod
add-light = (name, group, num) ->
	lights-db.add {name, group, num}
# turn-light :: String -> Boolean -> IO ()
turn-light = (name, state) ->
	id = lights-db.find \name name
	if !id then false
	else
		{group, num} = lights-db.data[id]
		turn group, num, state
		true

schedule-db = new Micro-DB do
	file: \schedule.db
# list-schedule :: Object Id, Object ScheduleEntry
list-schedule = -> schedule-db.data
# del-schedule :: Id -> DBMod
del-schedule = ->
	schedule-db.del it
	spit "sched  DEL - #it"
	exec-schedule!
# add-schedule :: Int -> Group -> Num -> Boolean -> String -> IO DBMod
add-schedule = (+time, group, num, state, desc = '') ->
	schedule-db.add {time, group, num, state, desc}
	spit "sched  ADD - #time #group #num #state #desc"
	exec-schedule!
# add-schedule-light :: Int -> String -> Boolean -> String -> IO DBMod
add-schedule-light = (+time, name, state, desc = '') ->
	schedule-db.add {time, name, state, desc}
	spit "sched  ADD - #time #name #state #desc"
	exec-schedule!
# add-schedule-light :: Int -> String -> IO DBMod
add-schedule-sched = (+time, desc = '') ->
	schedule-db.add {time, schedule-date: time, desc}
	spit "sched  ADD - #time sched #desc"
	exec-schedule!

schedule-run = (s) ->
	if s.name?
		turn-light s.name, s.state
	else if s.schedule-date?
		sun_sched.schedule-run do
			add-light: add-schedule-light
			add-sched: add-schedule-sched
			list:      list-schedule
			del:       del-schedule
			, s
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
		spit "sched  EMPTY"
		return
	now = Date.now!

	if s.time < now
		spit "sched  EXEC - #{s.time} #{s.desc}"
		process.next-tick -> schedule-run s
		schedule-db.del id
		exec-schedule!
	else
		spit "sched  DEFER - #{s.time}"
		schedule-timeout = set-timeout exec-schedule, (s.time - now + 100)

process.on \SIGINT !->
	lights-db.flush!
	schedule-db.flush!
	process.exit!

exec-schedule!
sun_sched.schedule-future do
	add-sched: add-schedule-sched
	list:      list-schedule
	del:       del-schedule

