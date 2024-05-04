package html

import "core:strings"
import "core:fmt"
import "core:time"

import "../base"

hidden_input :: proc(name: string, value: base.Value, data: []KeyValue = {}) -> string {
	return strings.concatenate([]string{"<input type=\"hidden\" name=\"", name, "\" ", attrs({{"value", value}}), attrs(data, "data-"), "/>"})
}

text_input :: proc(name: string, value: Maybe(string) = nil, placeholder: Maybe(string) = nil, class: []string = {}, data: []KeyValue = {}, autofocus: bool = false) -> string {
	return strings.concatenate([]string{"<input type=\"text\" name=\"", name, "\" ", attrs({{"value", base.value_from(value)}, {"placeholder", base.value_from(placeholder)}, {"class", strings.join(class, " ")}, {"autofocus", autofocus}}), attrs(data, "data-"), "/>"})
}

date_input :: proc(name: string, value: Maybe(time.Time) = nil, placeholder: Maybe(string) = nil, class: []string = {}, data: []KeyValue = {}, autofocus: bool = false) -> string {
	return strings.concatenate([]string{"<input type=\"date\" name=\"", name, "\" ", attrs({{"value", base.value_from(value)}, {"placeholder", base.value_from(placeholder)}, {"class", strings.join(class, " ")}, {"autofocus", autofocus}}), attrs(data, "data-"), "/>"})
}

date_time_input :: proc(name: string, value: Maybe(time.Time) = nil, placeholder: Maybe(string) = nil, class: []string = {}, data: []KeyValue = {}, autofocus: bool = false) -> string {
	return strings.concatenate([]string{"<input type=\"datetime-local\" name=\"", name, "\" ", attrs({{"value", base.value_from(value)}, {"placeholder", base.value_from(placeholder)}, {"class", strings.join(class, " ")}, {"autofocus", autofocus}}), attrs(data, "data-"), "/>"})
}

search_input :: proc(name: string, value: Maybe(string) = nil, placeholder: Maybe(string) = nil, class: []string = {}, data: []KeyValue = {}, autofocus: bool = false) -> string {
	return strings.concatenate([]string{"<input type=\"search\" name=\"", name, "\" ", attrs({{"value", base.value_from(value)}, {"placeholder", base.value_from(placeholder)}, {"class", strings.join(class, " ")}, {"autofocus", autofocus}}), attrs(data, "data-"), "/>"})
}

text_area :: proc(name: string, value: Maybe(string) = nil, placeholder: Maybe(string) = nil, rows: Maybe(int) = nil, class: []string = {}, data: []KeyValue = {}, autofocus: bool = false) -> string {
	return strings.concatenate([]string{"<textarea name=\"", name, "\" ", attrs({{"placeholder", base.value_from(placeholder)}, {"row", base.value_from(rows)}, {"class", strings.join(class, " ")}, {"autofocus", autofocus}}), attrs(data, "data-"), ">", value.? or_else "", "</textarea>"})
}

submit :: proc(value: string, class: []string = {}) -> string {
	return strings.concatenate([]string{"<input type=\"submit\" value=\"", value, "\" ", attrs({{"class", strings.join(class, " ")}}), "/>"})
}

label :: proc(for_name: string, text: string) -> string {
	return strings.concatenate([]string{"<label for=\"", for_name, "\">", text, "</label>"})
}

button :: proc(label: string, name: Maybe(string) = nil, value: Maybe(string) = nil, class: []string = {}) -> string {
	return strings.concatenate([]string{"<button ", attrs({{"name", base.value_from(name)}, {"value", base.value_from(value)}, {"class", strings.join(class, " ")}}), ">", label, "</button>"})
}