package database

import "core:strings"
import "core:log"
import "core:c"
import "core:c/libc"

import "lib:postgres"

ResultValue :: union {
	int,
	string,
	bool,
}

ResultColumn :: struct {
	type: postgres.Oid,
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

exec_result :: proc(conn: ^postgres.Conn, query: string, params: ..string) -> ^postgres.Result {
	length := len(params)
	cparams := make([]cstring, length, context.temp_allocator)
	for param, index in params {
		cparams[index] = strings.clone_to_cstring(params[index], context.temp_allocator)
	}
	return postgres.execParams(conn, strings.clone_to_cstring(query, context.temp_allocator), cast(c.int)length, nil, raw_data(cparams), nil, nil, 0)
}

parse_columns :: proc(result: ^postgres.Result) -> (columns: []ResultColumn, success: bool) {
	column_count := postgres.nfields(result)

	columns = make([]ResultColumn, column_count, context.temp_allocator)
	for c in 0..<column_count {
		columns[c].name = string(postgres.fname(result, c))
		columns[c].type = postgres.ftype(result, c)
	}
	return columns, true
}

parse_rows_as_string :: proc(result: ^postgres.Result) -> (res: []map[string]string, success: bool) {
	columns := parse_columns(result) or_return
	rows := postgres.ntuples(result)

	m := make([]map[string]string, rows, context.temp_allocator)

	for r in 0..<rows {
		for col, col_index in columns {
			cc := cast(c.int)col_index
			m[r][col.name] = string(postgres.getvalue(result, r, cc))
		}
	}

	return m, true
}

parse_rows :: proc(result: ^postgres.Result) -> (res: []map[string]ResultValue, success: bool) {
	columns := parse_columns(result) or_return
	rows := postgres.ntuples(result)

	m := make([]map[string]ResultValue, rows, context.temp_allocator)

	for r in 0..<rows {
		for col, col_index in columns {
			cc := cast(c.int)col_index
			val: ResultValue = nil

			if postgres.getisnull(result, r, cc) == 0 {
				raw_value := postgres.getvalue(result, r, cc)

				#partial switch col.type {
				case .int8, .int4, .int2:
					val = int(libc.atoll(raw_value))
				case .varchar:
					val = string(raw_value)
				case:
					log.error("Unsupported data type:", col.type)
				}
			}

			m[r][col.name] = val
		}
	}

	return m, true
}

exec_cmd :: proc(conn: ^postgres.Conn, query: string, params: ..string) -> (success: bool) {
	result := exec_result(conn, query, ..params)
	status := postgres.resultStatus(result)
	if status != .Command_OK {
		log.error("Error executing postgres command:", postgres.resStatus(status), postgres.resultErrorMessage(result))
		log.error(query)
		postgres.clear(result)
		return false
	}
	postgres.clear(result)
	return true
}

exec_query :: proc(conn: ^postgres.Conn, query: string, params: ..string) -> (res: []map[string]string, success: bool) {
	result := exec_result(conn, query, ..params)
	status := postgres.resultStatus(result)
	if status != .Tuples_OK {
		log.error("Error executing postgres query:", postgres.resStatus(status), postgres.resultErrorMessage(result))
		log.error(query)
		postgres.clear(result)
		return nil, false
	}
	return parse_rows_as_string(result)
}

exec_query_as_any :: proc(conn: ^postgres.Conn, query: string, params: ..string) -> (res: []map[string]ResultValue, success: bool) {
	result := exec_result(conn, query, ..params)
	status := postgres.resultStatus(result)
	if status != .Tuples_OK {
		log.error("Error executing postgres query:", postgres.resStatus(status), postgres.resultErrorMessage(result))
		postgres.clear(result)
		return nil, false
	}
	return parse_rows(result)
}