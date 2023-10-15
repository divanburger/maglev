package html

import "core:strings"
import "core:fmt"
import "core:time"

text_input :: proc(name: string, value: Maybe(string) = nil, placeholder: Maybe(string) = nil, class: []string = {}) -> string {
	return strings.concatenate([]string{"<input type=\"text\" name=\"", name, "\" ", attrs({{"value", value_from(value)}, {"placeholder", value_from(placeholder)}, {"class", strings.join(class, " ")}}), "/>"})
}

date_input :: proc(name: string, value: Maybe(time.Time) = nil, placeholder: Maybe(string) = nil, class: []string = {}) -> string {
	return strings.concatenate([]string{"<input type=\"date\" name=\"", name, "\" ", attrs({{"value", value_from(value)}, {"placeholder", value_from(placeholder)}, {"class", strings.join(class, " ")}}), "/>"})
}

date_time_input :: proc(name: string, value: Maybe(time.Time) = nil, placeholder: Maybe(string) = nil, class: []string = {}) -> string {
	return strings.concatenate([]string{"<input type=\"datetime-local\" name=\"", name, "\" ", attrs({{"value", value_from(value)}, {"placeholder", value_from(placeholder)}, {"class", strings.join(class, " ")}}), "/>"})
}

text_area :: proc(name: string, value: Maybe(string) = nil, placeholder: Maybe(string) = nil, rows: Maybe(int) = nil, class: []string = {}) -> string {
	return strings.concatenate([]string{"<textarea name=\"", name, "\" ", attrs({{"placeholder", value_from(placeholder)}, {"row", value_from(rows)}, {"class", strings.join(class, " ")}}), ">", value.? or_else "", "</textarea>"})
}

submit :: proc(value: string, class: []string = {}) -> string {
	return strings.concatenate([]string{"<input type=\"submit\" value=\"", value, "\" ", attrs({{"class", strings.join(class, " ")}}), "/>"})
}

label :: proc(for_name: string, text: string) -> string {
	return strings.concatenate([]string{"<label for=\"", for_name, "\">", text, "</label>"})
}