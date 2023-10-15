package base

import "core:log"
import "core:time"

import http "lib:odin-http"

handler :: proc(handler: ^http.Handler, req: ^http.Request, res: ^http.Response) {
	stopwatch: time.Stopwatch
	time.stopwatch_start(&stopwatch)

	next := handler.next.(^http.Handler)
	next.handle(next, req, res)

	time.stopwatch_stop(&stopwatch)

	line, _ := req.line.?
	log.info(line.method, line.target, res.status, time.stopwatch_duration(stopwatch))
}