package request

import "core:log"
import "core:encoding/json"
import http "lib:odin-http"

Parse_Form_Body_Callback :: proc(req: ^http.Request, res: ^http.Response, form: map[string]string)
Parse_JSON_Body_Callback :: proc(req: ^http.Request, res: ^http.Response, json: json.Value)

Form_Request_Response :: struct {
	req: ^http.Request,
	res: ^http.Response,
	cb: Parse_Form_Body_Callback,
}

JSON_Request_Response :: struct {
	req: ^http.Request,
	res: ^http.Response,
	cb: Parse_JSON_Body_Callback,
}

parse_form_body :: proc(req: ^http.Request, res: ^http.Response, cb: Parse_Form_Body_Callback) {
	data := new_clone(Form_Request_Response{req, res, cb})
	http.body(req, -1, data, proc(user_ptr: rawptr, body: http.Body, err: http.Body_Error) {
		data := cast(^Form_Request_Response)user_ptr

		if err != nil {
			http.respond(data.res, http.body_error_status(err))
			log.error(err)
			return
		}

		result, ok := http.body_url_encoded(body)
		if !ok {
			http.respond(data.res, http.Status.Bad_Request)
			log.error(err)
			return
		}

		data.cb(data.req, data.res, result)
	})
}

parse_json_body :: proc(req: ^http.Request, res: ^http.Response, cb: Parse_JSON_Body_Callback) {
	data := new_clone(JSON_Request_Response{req, res, cb})
	http.body(req, -1, data, proc(user_ptr: rawptr, body: http.Body, err: http.Body_Error) {
		data := cast(^JSON_Request_Response)user_ptr

		if err != nil {
			http.respond(data.res, http.body_error_status(err))
			log.error(err)
			return
		}

		result, err := json.parse(transmute([]u8)body)
		if err != .None {
			http.respond(data.res, http.Status.Bad_Request)
			log.error(err)
			return
		}

		data.cb(data.req, data.res, result)
	})
}