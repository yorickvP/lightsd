require! [\fs \path]
relative-root = ->
	path.resolve __dirname, "../", it
read-JSON-sync = ->
	try
		JSON.parse fs.read-file-sync relative-root it
	catch {code}:e
		switch code
		| "ENOENT"  => null
		| otherwise => throw e
try-multiple = (files) ->
	for file in files
		c = read-JSON-sync file
		return c if !!c
	{}
merge-defaults = (a, fallback) ->
	if Array.isArray fallback
		if a then that
		else fallback
	if typeof fallback == "object"
		{[k, if a[k]? then merge-defaults a[k], fb else fb] for own k,fb of fallback}
	else if a? then a
	else fallback
get-config = ->
	{HOME} = process.env
	merge-defaults do
		try-multiple [ \config.json "#HOME/.config/lights.conf.json" ]
		read-JSON-sync \config.default.json
module.exports = get-config!
