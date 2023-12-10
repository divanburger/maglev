package jwt

import "core:strings"
import "core:encoding/base64"
import "core:encoding/json"

decode :: proc(token: string) -> (header: json.Object, payload: json.Object, valid: bool) {
	parts := strings.split_n(token, ".", 3)
	header_str := base64.decode(parts[0])
	payload_str := base64.decode(parts[1])
	header_json, header_err := json.parse(header_str)
	if header_err != .None do return
	payload_json, payload_err := json.parse(payload_str)
	if payload_err != .None do return

	header = header_json.? or_return
	payload = payload_json.? or_return
	valid = true
	return
}