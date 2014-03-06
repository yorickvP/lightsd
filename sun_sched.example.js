
function startTime(d, sun) {
	return sun.sunsetStart }
function endTime(d) {
	var end = new Date(d)
	switch(d.getDay()) {
		case 0: case 1: case 2: case 3: case 4:
			end.setHours(23, 15)
			break
		default:
			end.setDate(end.getDate() + 1)
			end.setHours(0, 0)
			break }
	return end }
function dateRepr(d) {
	return [d.getFullYear(), d.getMonth(), d.getDate()].join("-") }

// export a function that is run daily
// use sunTimes to calculate when the sun
// comes up/down on a lat/long.
// return: [lightname, state, desc, time]

// keep in mind that these descriptions should not clash with any
// other ones you're using, because every schedule item with the same
// ones will be removed.
function timesForDay(day, sunTimes) {
	var sun = sunTimes(52.22, 5.15)
	var repr = dateRepr(day)
	var start = startTime(day, sun)
	var end = endTime(day, sun)
	return [
		/*['your_light', true, "sunset " + repr, start],
		  ['your_light', false, "night " + repr, end] */]}

module.exports = timesForDay
