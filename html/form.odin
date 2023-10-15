package html

import "core:strings"
import "core:fmt"
import "core:time"


form_text_input :: proc(name: string, text: string, value: Maybe(string) = nil, placeholder: Maybe(string) = nil, autofocus: bool = false, data: []KeyValue = {}) -> string {
	return strings.concatenate([]string{label(name, text), text_input(name, value, placeholder, autofocus=autofocus, data=data)})
}

form_date_input :: proc(name: string, text: string, value: Maybe(time.Time) = nil, placeholder: Maybe(string) = nil, autofocus: bool = false, data: []KeyValue = {}) -> string {
	return strings.concatenate([]string{label(name, text), date_input(name, value, placeholder, autofocus=autofocus, data=data)})
}

form_date_time_input :: proc(name: string, text: string, value: Maybe(time.Time) = nil, placeholder: Maybe(string) = nil, autofocus: bool = false, data: []KeyValue = {}) -> string {
	return strings.concatenate([]string{label(name, text), date_time_input(name, value, placeholder, autofocus=autofocus, data=data)})
}

form_search_input :: proc(name: string, text: string, value: Maybe(string) = nil, placeholder: Maybe(string) = nil, autofocus: bool = false, data: []KeyValue = {}) -> string {
	return strings.concatenate([]string{label(name, text), search_input(name, value, placeholder, autofocus=autofocus, data=data)})
}

form_text_area :: proc(name: string, text: string, value: Maybe(string) = nil, placeholder: Maybe(string) = nil, rows: Maybe(int) = nil, autofocus: bool = false, data: []KeyValue = {}) -> string {
	return strings.concatenate([]string{label(name, text), text_area(name, value, placeholder, rows, autofocus=autofocus, data=data)})
}