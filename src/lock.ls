class Lock
	locked: false
	->
		@requesters = []
	get: (cb) ->
		if @locked
			@requesters.push cb
			false
		else
			@locked = true
			cb!
			true
	free: ->
		if @requesters.length
			@requesters.shift!!
		else
			@locked = false
module.exports = Lock
