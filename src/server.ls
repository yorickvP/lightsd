require! [http,connect, path, fs, url, moment]
require! {mu: 'mu2'}
moment.lang \en-gb
# schedule-add-light time, name, state, desc = ''

relative = (p) ->
	path.resolve __dirname, \../ p

mu.root = relative \web

plaintext = (data, res) -->
	res.write-head 200 do
		'Content-Length': data.length
		'Content-Type': "text/plain; charset=UTF-8"
	res.end data

redirect = (url, res) -->
	res.write-head 303 do
		'Location': '/'
	res.end!


index-template = (remote, res) ->
	lights <- remote.lights.list!
	lights = [v for ,v of lights]
	sched  <- remote.schedule.list!
	sched  = [v <<< {id} for id,v of sched]
	# use moment.js for nice time formatting
	sched .for-each (s) -> s.moment = moment(s.time)calendar!
	# find matching schedule items for every light
	lights.for-each (l) -> l.sched  = sched.filter (.name == l.name)
	res.write-head 200 do
		'Content-Type': "text/html; charset=UTF-8"
	mu.compile-and-render \index.tmpl {lights, sched} .pipe res
pathname = (req-url) -> url.parse req-url .pathname

schedule-add = (remote, {body}, res) ->
	{\sched-add-state : state
	\sched-add-time   : time
	\sched-add-light  : light} = body
	time = new Date time
	<- remote.schedule.add-light +time, light, (state == 'on'), 'Added from web'
	redirect \/ res


module.exports = server = (remote, port) ->
	turn = remote.lights.turn
	okay = plaintext 'okay'
	http.create-server do
		connect!
		.use connect.logger \dev
		.use connect.query!
		.use connect.body-parser!
		.use ({query: {light, id}, url}:req, res, next) !->
			switch pathname url
			| \/    => index-template remote, res
			| \/on  => turn light, on  -> okay res
			| \/off => turn light, off -> okay res
			| \/sched-add => schedule-add remote, req, res
			| \/sched-del => remote.schedule.del id, -> redirect \/ res
			| _     => next!
		.use connect.static relative \web
		.use connect.error-handler!
	.listen port
