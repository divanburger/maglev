package html

import "core:os"
import "core:strings"

Builder :: struct {
	contents: [dynamic]string,
}

builder_start :: proc(builder: ^Builder) {
	builder.contents = make([dynamic]string, 0, 6)
}

builder_done :: proc(builder: ^Builder) -> string {
	return strings.concatenate(builder.contents[:], context.temp_allocator)
}

link_to :: proc(builder: ^Builder, inner: string, link: string) {
	append(&builder.contents, "<a href=\"")
	append(&builder.contents, link)
	append(&builder.contents, "\">")
	append(&builder.contents, inner)
	append(&builder.contents, "</a>")
}

div_with_string :: proc(builder: ^Builder, inner: string) {
	append(&builder.contents, "<div>")
	append(&builder.contents, inner)
	append(&builder.contents, "</div>")
}

div_with_proc :: proc(builder: ^Builder, inner: proc()) {
	append(&builder.contents, "<div>")
	inner()
	append(&builder.contents, "</div>")
}

div :: proc{
	div_with_proc,
	div_with_string,
}

span_with_string :: proc(builder: ^Builder, inner: string) {
	append(&builder.contents, "<span>")
	append(&builder.contents, inner)
	append(&builder.contents, "</span>")
}

span_with_proc :: proc(builder: ^Builder, inner: proc()) {
	append(&builder.contents, "<span>")
	inner()
	append(&builder.contents, "</span>")
}

span :: proc{
	span_with_proc,
	span_with_string,
}

list_start :: proc(builder: ^Builder) {
	append(&builder.contents, "<ul>")
}

list_end :: proc(builder: ^Builder) {
	append(&builder.contents, "</ul>")
}

list_item :: proc(builder: ^Builder, inner: string) {
	append(&builder.contents, "<li>")
	append(&builder.contents, inner)
	append(&builder.contents, "</li>")
}


list_item_start :: proc(builder: ^Builder) {
	append(&builder.contents, "<li>")
}

list_item_end :: proc(builder: ^Builder) {
	append(&builder.contents, "</li>")
}

from_file :: proc(builder: ^Builder, file_path: string) {
	contents := os.read_entire_file_from_filename(file_path) or_else transmute([]u8)file_path
	append(&builder.contents, string(contents))
}