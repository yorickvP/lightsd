
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


function timesForDay(day, sunTimes) {
	var sun = sunTimes(52.22, 5.15)
	var repr = dateRepr(day)
	var start = startTime(day, sun)
	var end = endTime(day, sun)
	return [
		['schoorsteen', true, "sunset " + repr, start],
		['schoorsteen', false, "night " + repr, end]]}

module.exports = timesForDay
