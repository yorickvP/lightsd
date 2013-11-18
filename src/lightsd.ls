require! [airport, \./lock]
require! MicroDB: \nodejs-microdb
settings =
	host: \frumar.yori.cc
	port: 9090
	version: \0.0.2

# spit :: IO ()
spit = -> process.stdout.write it + \\n

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
.listen \lightsd@ + settings.version

{spawn} = require \child_process


turn-lock = new lock
# turn :: Group -> Num -> Boolean -> IO ()
turn = (group, num, state) !->
	if typeof state is \boolean
		state = if state then \on else \off
	turn-lock.get ->
		console.log "Turning #state #group #num"
		proc = spawn \./kaku [group, num, state]
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
	exec-schedule!
# add-schedule :: Int -> Group -> Num -> Boolean -> String -> IO DBMod
add-schedule = (+time, group, num, state, desc = '') ->
	schedule-db.add {time, group, num, state, desc}
	exec-schedule!
# add-schedule-light :: Int -> String -> Boolean -> String -> IO DBMod
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
		spit "Nothing scheduled"
		return
	now = Date.now!

	if s.time < now
		spit "executing something"
		process.next-tick -> schedule-run s
		schedule-db.del id
		exec-schedule!
	else
		spit "Scheduling into the future"
		schedule-timeout = set-timeout exec-schedule, (s.time - now + 100)

process.on \SIGINT !->
	lights-db.flush!
	schedule-db.flush!
	process.exit!

exec-schedule!
