package base

import "core:time"

Safe_Html :: struct {
	text: string,
}

Value :: union {
	string,
	int,
	f64,
	bool,
	time.Time,
	Safe_Html,
}

safe_html :: proc(str: string) -> Safe_Html {
	return Safe_Html{str}
}

value_from_maybe_string :: #force_inline proc(val: Maybe(string)) -> Value {
	v, ok := val.?
	return ok ? v : nil
}

value_from_maybe_int :: #force_inline proc(val: Maybe(int)) -> Value {
	v, ok := val.?
	return ok ? v : nil
}

value_from_maybe_time :: #force_inline proc(val: Maybe(time.Time)) -> Value {
	v, ok := val.?
	return ok ? v : nil
}

value_from :: proc{
	value_from_maybe_string,
	value_from_maybe_int,
	value_from_maybe_time,
}