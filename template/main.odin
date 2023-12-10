package template

import "core:os"
import "core:strings"
import "core:log"
import "core:c/libc"

parse_template :: proc(input_filename: string, output_filename: string, main: string) -> (success: bool) {
	State :: enum { Outside, Going_In_1, Going_In_2, Inside, Going_Out_1, Going_Out_2 }

	init_state: bool = false
	state: State
	output: bool = false
	line_no: int = 1

	contents, ok_in := os.read_entire_file(input_filename)
	if !ok_in {
		log.error("Could not open", input_filename)
		return false
	}

	result, err_out := os.open(output_filename, os.O_CREATE | os.O_TRUNC | os.O_WRONLY, 0o644)
	if err_out != os.ERROR_NONE {
		log.error("Could not open", output_filename, ": error", err_out)
		return false
	}
	defer os.close(result)

	INIT :: `package partials

import "core:strings"
import "core:os"
import "core:time"
import "core:fmt"
import "core:log"

import "lib:postgres"

import "lib:maglev/base"
import "lib:maglev/assets"
import "lib:maglev/html"
import "lib:maglev/session"
import db "lib:maglev/database"

import "../../app/events"

`
	INIT2 :: " :: proc("
	INIT3 :: ") -> (_result: string, _ok: bool) #optional_ok {\n\tusing html\n\tb := strings.builder_make(allocator = context.temp_allocator)\n\n"

	TEXT_PREFIX :: "\tstrings.write_string(&b,`"
	TEXT_SUFFIX :: "`)\n"

	OUT_PREFIX :: "\thtml.write_value(&b,"
	OUT_SUFFIX :: ")"

	buf := strings.builder_make(allocator = context.temp_allocator)

	for i := 0; i < len(contents); i += 1 {
		c := contents[i]
		switch c {
		case '<':
			if state == .Outside {
				state = .Going_In_1
			} else {
				strings.write_byte(&buf, '<')
			}
		case '%':
			if state == .Going_In_1 {
				state = .Going_In_2
				output = false
			} else if (state == .Going_In_2 || state == .Inside) {
				state = .Going_Out_1
			} else {
				strings.write_byte(&buf, '%')
			}
		case '=':
			if state == .Going_In_2 {
				output = true
			} else {
				strings.write_byte(&buf, '=')
			}
		case '>':
			if state == .Going_Out_1 {
				state = .Going_Out_2
			} else {
				strings.write_byte(&buf, '>')
			}
		case:
			if c == '\n' do line_no += 1
			if state == .Going_In_1 {
				state = .Outside
				strings.write_byte(&buf, '<')
			}
			if state == .Going_Out_1 {
				state = .Inside
				strings.write_byte(&buf, '%')
			}
			if state == .Going_In_2 {
				state = .Inside
			}
			strings.write_byte(&buf, c)
		}

		#partial switch state {
			case .Going_In_2:
				if strings.builder_len(buf) > 0 {
					if (!init_state) {
						os.write_string(result, INIT)
						os.write_string(result, main)
						os.write_string(result, INIT2)
						os.write_string(result, INIT3)
						init_state = true
					}
					os.write_string(result, TEXT_PREFIX)
					os.write(result, buf.buf[:])
					os.write_string(result, TEXT_SUFFIX)
				}
				strings.builder_reset(&buf)
			case .Going_Out_2:
				state = .Outside
				res := strings.to_string(buf)
				if (!init_state) {
					os.write_string(result, INIT)
					os.write_string(result, main)
					os.write_string(result, INIT2)
					if (strings.has_prefix(res, "@")) {
						os.write_string(result, strings.trim(res, "@()"))
						res = ""
					}
					os.write_string(result, INIT3)
					init_state = true
				}
				if (len(res) > 0) {
					if output do os.write_string(result, OUT_PREFIX)
					os.write_string(result, res)
					if output do os.write_string(result, OUT_SUFFIX)
					os.write_string(result, "\n")
				}
				strings.builder_reset(&buf)
		}
	}

	if (!init_state) {
		os.write_string(result, INIT)
		os.write_string(result, main)
		os.write_string(result, INIT2)
		os.write_string(result, INIT3)
		init_state = true
	}

	if strings.builder_len(buf) > 0 {
		os.write_string(result, TEXT_PREFIX)
		os.write(result, buf.buf[:])
		os.write_string(result, TEXT_SUFFIX)
	}
	os.write_string(result, "\n\treturn strings.to_string(b), true\n}\n")

	return true
}