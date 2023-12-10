package turbo

import "core:fmt"
import "core:log"
import "core:net"
import "core:time"
import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:text/match"

import http "lib:odin-http"

TurboStream :: [dynamic]string

make_turbo_stream :: proc(allocator := context.temp_allocator) -> TurboStream {
	return make(TurboStream, 0, 4, allocator)
}

stream_replace :: proc(target: string, content: string) -> string {
	return strings.concatenate([]string{"<turbo-stream action=\"replace\" target=\"", target, "\"><template>", content, "</template></turbo-stream>"})
}

stream_append :: proc(target: string, content: string) -> string {
	return strings.concatenate([]string{"<turbo-stream action=\"append\" target=\"", target, "\"><template>", content, "</template></turbo-stream>"})
}

add_stream_replace :: proc(stream: ^TurboStream, target: string, content: string) {
	append(stream, stream_replace(target, content))
}

add_stream_append :: proc(stream: ^TurboStream, target: string, content: string) {
	append(stream, stream_append(target, content))
}

respond_with_stream_obj :: proc (r: ^http.Response, stream: TurboStream, loc := #caller_location) {
	r.status = .OK
	http.headers_set(&r.headers, "content-type", "text/vnd.turbo-stream.html")
	http.body_set(r, strings.concatenate(stream[:]), loc)
	http.respond(r, loc)
}

respond_with_stream_html :: proc (r: ^http.Response, html: string, loc := #caller_location) {
	r.status = .OK
	http.headers_set(&r.headers, "content-type", "text/vnd.turbo-stream.html")
	http.body_set(r, html, loc)
	http.respond(r, loc)
}

respond_with_stream :: proc{
	respond_with_stream_obj,
	respond_with_stream_html,
}