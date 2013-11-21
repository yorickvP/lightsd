require! [\fs \path]
relative-root = ->
	path.join __dirname, "/../", it
read-JSON-sync = ->
	try
		JSON.parse fs.read-file-sync relative-root it
	catch {code}:e
		switch code
		| "ENOENT"  => {}
		| otherwise => throw e
merge-defaults = (a, fallback) ->
	if Array.isArray fallback
		if a then that
		else fallback
	if typeof fallback == "object"
		{[k, if a[k]? then merge-defaults a[k], fb else fb] for own k,fb of fallback}
	else if a? then a
	else fallback
get-config = ->
	merge-defaults do
		read-JSON-sync \config.json
		read-JSON-sync \config.default.json
module.exports = get-config!
