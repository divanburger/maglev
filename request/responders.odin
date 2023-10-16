package request

import "core:log"
import http "lib:odin-http"

Parse_Form_Body_Callback :: proc(req: ^http.Request, res: ^http.Response, form: map[string]string)

Request_Response :: struct {
	req: ^http.Request,
	res: ^http.Response,
	cb: Parse_Form_Body_Callback
}

parse_form_body :: proc(req: ^http.Request, res: ^http.Response, cb: Parse_Form_Body_Callback) {
	data := new_clone(Request_Response{req, res, cb})
	http.body(req, -1, data, proc(user_ptr: rawptr, body: http.Body, err: http.Body_Error) {
		data := cast(^Request_Response)user_ptr

		if err != nil {
			http.respond(data.res, http.body_error_status(err))
			log.error(err)
			return
		}

		result, ok := http.body_url_encoded(body)
		if !ok {
			http.respond(data.res, http.Status.Internal_Server_Error)
			log.error(err)
			return
		}

		data.cb(data.req, data.res, result)
	})
}