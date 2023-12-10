package html

import "core:strings"
import "core:fmt"
import "core:time"

import "../base"

KeyValue :: struct {
	key: string,
	val: base.Value,
}

write_padded_number :: proc(builder: ^strings.Builder, i: i64, width: int) {
	n := width-1
	for x := i; x >= 10; x /= 10 {
		n -= 1
	}
	for _ in 0..<n {
		strings.write_byte(builder, '0')
	}
	strings.write_i64(builder, i, 10)
}

write_iso_date_time_to_the_minute :: proc(builder: ^strings.Builder, t: time.Time) {
	y, mon, d := time.date(t)
	h, min, _ := time.clock(t)
	write_padded_number(builder, i64(y), 4)
	strings.write_byte(builder, '-')
	write_padded_number(builder, i64(mon), 2)
	strings.write_byte(builder, '-')
	write_padded_number(builder, i64(d), 2)
	strings.write_byte(builder, 'T')

	write_padded_number(builder, i64(h), 2)
	strings.write_byte(builder, ':')
	write_padded_number(builder, i64(min), 2)
}

write_iso_date_time :: proc(builder: ^strings.Builder, t: time.Time) {
	y, mon, d := time.date(t)
	h, min, s := time.clock(t)
	ns := (t._nsec - (t._nsec/1e9 + time.UNIX_TO_ABSOLUTE)*1e9) % 1e9
	write_padded_number(builder, i64(y), 4)
	strings.write_byte(builder, '-')
	write_padded_number(builder, i64(mon), 2)
	strings.write_byte(builder, '-')
	write_padded_number(builder, i64(d), 2)
	strings.write_byte(builder, 'T')

	write_padded_number(builder, i64(h), 2)
	strings.write_byte(builder, ':')
	write_padded_number(builder, i64(min), 2)
	strings.write_byte(builder, ':')
	write_padded_number(builder, i64(s), 2)
	strings.write_byte(builder, '.')
	write_padded_number(builder, (ns), 9)
	strings.write_string(builder, "Z")
}

write_value :: proc(builder: ^strings.Builder, value: base.Value) {
	switch val in value {
		case string:
			strings.write_string(builder, val)
		case base.Safe_Html:
			strings.write_string(builder, val.text)
		case int:
			strings.write_int(builder, val)
		case f64:
			strings.write_f64(builder, val, 'f')
		case bool:
			strings.write_byte(builder, val ? '1' : '0')
		case time.Time:
			write_iso_date_time(builder, val)
		case:
	}
}

attrs_with_map :: proc(attrs: map[string]base.Value) -> string {
	builder := strings.builder_make(context.temp_allocator)

	for key, value in attrs {
		switch val in value {
			case string:
				if len(val) > 0 {
					strings.write_string(&builder, key)
					strings.write_string(&builder, "=\"")
					strings.write_string(&builder, val)
					strings.write_string(&builder, "\" ")
				}
			case base.Safe_Html:
				if len(val.text) > 0 {
					strings.write_string(&builder, key)
					strings.write_string(&builder, "=\"")
					strings.write_string(&builder, val.text)
					strings.write_string(&builder, "\" ")
				}
			case int:
				strings.write_string(&builder, key)
				strings.write_string(&builder, "=\"")
				strings.write_int(&builder, val)
				strings.write_string(&builder, "\" ")
			case f64:
				strings.write_string(&builder, key)
				strings.write_string(&builder, "=\"")
				strings.write_f64(&builder, val, 'f')
				strings.write_string(&builder, "\" ")
			case bool:
				if val {
					strings.write_string(&builder, key)
					strings.write_string(&builder, "=\"")
					strings.write_string(&builder, key)
					strings.write_string(&builder, "\" ")
				}
			case time.Time:
				strings.write_string(&builder, key)
				strings.write_string(&builder, "=\"")
				write_iso_date_time_to_the_minute(&builder, val)
				strings.write_string(&builder, "\" ")
			case:
		}
	}

	return strings.to_string(builder)
}

attrs :: proc(attrs: []KeyValue, prefix: string = "") -> string {
	builder := strings.builder_make(context.temp_allocator)

	for kv in attrs {
		switch val in kv.val {
			case string:
				if len(val) > 0 {
					strings.write_string(&builder, prefix)
					strings.write_string(&builder, kv.key)
					strings.write_string(&builder, "=\"")
					strings.write_string(&builder, val)
					strings.write_string(&builder, "\" ")
				}
			case base.Safe_Html:
				if len(val.text) > 0 {
					strings.write_string(&builder, prefix)
					strings.write_string(&builder, kv.key)
					strings.write_string(&builder, "=\"")
					strings.write_string(&builder, val.text)
					strings.write_string(&builder, "\" ")
				}
			case int:
				strings.write_string(&builder, prefix)
				strings.write_string(&builder, kv.key)
				strings.write_string(&builder, "=\"")
				strings.write_int(&builder, val)
				strings.write_string(&builder, "\" ")
			case f64:
				strings.write_string(&builder, prefix)
				strings.write_string(&builder, kv.key)
				strings.write_string(&builder, "=\"")
				strings.write_f64(&builder, val, 'f')
				strings.write_string(&builder, "\" ")
			case bool:
				if val {
					strings.write_string(&builder, prefix)
					strings.write_string(&builder, kv.key)
					strings.write_string(&builder, "=\"")
					strings.write_string(&builder, kv.key)
					strings.write_string(&builder, "\" ")
				}
			case time.Time:
				strings.write_string(&builder, prefix)
				strings.write_string(&builder, kv.key)
				strings.write_string(&builder, "=\"")
				write_iso_date_time_to_the_minute(&builder, val)
				strings.write_string(&builder, "\" ")
			case:
		}
	}

	return strings.to_string(builder)
}