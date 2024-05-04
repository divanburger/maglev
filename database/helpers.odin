package database

import "core:strings"
import "core:log"
import "core:c"
import "core:c/libc"
import "core:fmt"
import "core:time"
import "core:strconv"

import postgres "lib:odin-postgresql"

import "../base"

OID :: enum c.uint {
	boolean = 16,
	bytea = 17,
	char = 18,
	name = 19,
	int8 = 20,
	int2 = 21,
	int2vector = 22,
	int4 = 23,
	text = 25,
	varchar = 1043,
	date = 1082,
	time = 1083,
	timestamp = 1114,
	timestamptz = 1184,
}

ResultColumn :: struct {
	type: postgres.OID,
	name: string,
}

_parse_int :: proc(s: string, offset: int) -> (result: int, new_offset: int, ok: bool) {
	is_digit :: #force_inline proc(r: byte) -> bool { return '0' <= r && r <= '9' }

	new_offset = offset
	for new_offset < len(s) {
		c := s[new_offset]
		is_digit(c) or_break

		new_offset += 1

		result *= 10
		result += int(c)-'0'
	}
	ok = new_offset > offset
	return
}

convert_value_to_db :: proc(value: base.Value) -> Maybe(string) {
	#partial switch val in value {
		case string:
			return val
		case int:
			return fmt.tprint(val)
		case f64:
			return fmt.tprint(val)
		case bool:
			return val ? "true" : "false"
		case nil:
			return "NULL"
		case:
			log.error("Unsupport data type: ", val)
			return ""
	}
}

exec_result :: proc(query: string, params: ..base.Value, location := #caller_location) -> (result: postgres.Result) {
	stopwatch: time.Stopwatch
	time.stopwatch_start(&stopwatch)

	length := len(params)
	cparams := make([][^]u8, length, context.temp_allocator)
	for param, index in params {
		val := convert_value_to_db(param).(string) or_else ""
		cparams[index] = transmute([^]u8)strings.clone_to_cstring(val, context.temp_allocator)
	}
	result = postgres.exec_params(conn, strings.clone_to_cstring(query, context.temp_allocator), cast(c.int)length, nil, raw_data(cparams), nil, nil, .Text)

	time.stopwatch_stop(&stopwatch)
	log.info(time.stopwatch_duration(stopwatch), query, location = location)
	return
}

parse_columns :: proc(result: postgres.Result) -> (columns: []ResultColumn, success: bool) {
	column_count := postgres.n_fields(result)

	columns = make([]ResultColumn, column_count, context.temp_allocator)
	for c in 0..<column_count {
		columns[c].name = strings.clone_from_cstring(postgres.f_name(result, c), context.temp_allocator)
		columns[c].type = postgres.f_type(result, c)
	}
	return columns, true
}

parse_rows_as_string :: proc(result: postgres.Result) -> (res: []map[string]string, success: bool) {
	columns := parse_columns(result) or_return
	rows := postgres.n_tuples(result)

	m := make([]map[string]string, rows, context.temp_allocator)

	for r in 0..<rows {
		for col, col_index in columns {
			cc := cast(c.int)col_index
			m[r][col.name] = string(cstring(postgres.get_value(result, r, cc)))
		}
	}

	return m, true
}

parse_date :: proc(value: string) -> (t: time.Time, ok: bool) {
	value := value

	year := strconv.parse_i64_of_base(value[0:4], 10) or_return
	month := strconv.parse_i64_of_base(value[5:7], 10) or_return
	day := strconv.parse_i64_of_base(value[8:10], 10) or_return

	hour := strconv.parse_i64_of_base(value[11:13], 10) or_return
	minute := strconv.parse_i64_of_base(value[14:16], 10) or_return
	seconds := strconv.parse_i64_of_base(value[17:19], 10) or_return

	nanoseconds := 0
	if len(value) > 19 {
		rest := strconv.parse_f64(value[19:]) or_return
		nanoseconds = int(rest * 1000000000)
	}
	
	t = time.datetime_to_time(int(year), int(month), int(day) + 1, int(hour), int(minute), int(seconds), nanoseconds) or_return
	ok = true
	return
}

parse_rows :: proc(result: postgres.Result) -> (res: []map[string]base.Value, success: bool) {
	columns := parse_columns(result) or_return
	rows := postgres.n_tuples(result)

	m := make([]map[string]base.Value, rows, context.temp_allocator)

	for r in 0..<rows {
		for col, col_index in columns {
			cc := cast(c.int)col_index
			val: base.Value = nil

			if !postgres.get_is_null(result, r, cc) {
				raw_value := postgres.get_value(result, r, cc)

				#partial switch transmute(OID)col.type {
				case OID.int8, OID.int4, OID.int2:
					val = cast(int)strconv.parse_int(string(cstring(raw_value))) or_return
				case OID.varchar:
					val = string(cstring(raw_value))
				case OID.timestamp:
					val = parse_date(string(cstring(raw_value))) or_return
				case OID.boolean:
					val = raw_value != nil && raw_value[0] == 't'
				case:
					log.error("Unsupported data type:", col.type)
				}
			}

			m[r][col.name] = val
		}
	}

	return m, true
}

exec_cmd :: proc(query: string, params: ..base.Value, location := #caller_location) -> (success: bool) {
	result := exec_result(query, ..params, location=location)
	defer postgres.clear(result)
	status := postgres.result_status(result)
	if status != .Command_OK && status != .Tuples_OK {
		log.error("Error executing postgres command:", postgres.res_status(status), status, postgres.result_error_message(result), location=location)
		log.error(query, location=location)
		return false
	}
	return true
}

exec_exist :: proc(query: string, params: ..base.Value, location := #caller_location) -> (exist: bool, success: bool) {
	result := exec_result(query, ..params, location=location)
	defer postgres.clear(result)
	status := postgres.result_status(result)
	if status != .Tuples_OK {
		log.error("Error executing postgres command:", postgres.res_status(status), status, postgres.result_error_message(result), location=location)
		log.error(query, location=location)
		return false, false
	}
	return postgres.n_tuples(result) > 0, true
}

exec_row_count :: proc(query: string, params: ..base.Value, location := #caller_location) -> (rows: int, success: bool) {
	result := exec_result(query, ..params, location=location)
	defer postgres.clear(result)
	status := postgres.result_status(result)
	if status != .Tuples_OK {
		log.error("Error executing postgres command:", postgres.res_status(status), status, postgres.result_error_message(result), location=location)
		log.error(query, location=location)
		return 0, false
	}
	return int(postgres.n_tuples(result)), true
}

exec_query_as_str :: proc(query: string, params: ..base.Value, location := #caller_location) -> (res: []map[string]string, success: bool) {
	result := exec_result(query, ..params, location=location)
	defer postgres.clear(result)
	status := postgres.result_status(result)
	if status != .Tuples_OK {
		log.error("Error executing postgres query:", postgres.res_status(status), status, postgres.result_error_message(result))
		log.error(query, location=location)
		return nil, false
	}
	return parse_rows_as_string(result)
}

exec_query :: proc(query: string, params: ..base.Value, location := #caller_location) -> (res: []map[string]base.Value, success: bool) {
	result := exec_result(query, ..params, location=location)
	defer postgres.clear(result)
	status := postgres.result_status(result)
	if status != .Tuples_OK {
		log.error("Error executing postgres query:", postgres.res_status(status), status, postgres.result_error_message(result), location=location)
		log.error(query, location=location)
		return nil, false
	}
	return parse_rows(result)
}