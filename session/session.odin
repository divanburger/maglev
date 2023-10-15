package session

import "core:crypto/sha3"
import "core:math/rand"
import "core:encoding/base64"
import "core:time"
import "core:log"
import "core:fmt"

import http "lib:odin-http"

import db "../database"

Session :: struct {
	key: string,
	user_id: Maybe(int),
}

@thread_local
session: Session

generate_key :: proc() -> string {
	bytes := transmute([8]u8)rand.uint64
	hashed_bytes := sha3.hash_bytes_256(bytes[:])
	return base64.encode(hashed_bytes[:])
}

save :: proc() {
	db.exec_cmd(db.conn, "UPDATE sessions SET user_id = $2, last_accessed_at = NOW() WHERE key = $1", session.key, fmt.tprint(session.user_id))
}

handler :: proc(handler: ^http.Handler, req: ^http.Request, res: ^http.Response) {
	session = Session{}

	session_key, ok := http.request_cookie_get(req, "session_key")
	if ok {
		// log.info("Request had key:", session_key)
		values, get_ok := db.exec_query_as_any(db.conn, "SELECT key, user_id FROM sessions WHERE key = $1", session_key)
		if get_ok && len(values) == 1 {
			upd_ok := db.exec_cmd(db.conn, "UPDATE sessions SET last_accessed_at = NOW() WHERE key = $1", session_key)
			user_id, user_id_ok := values[0]["user_id"].(int)
			session.user_id = user_id_ok ? user_id : nil
			// log.info("Session had user:", session.user_id)
		} else {
			log.info("Could not retrieve session")
			ok = false
		}
	}

	if !ok {
		session_key := generate_key()
		log.info("Provided key:", session_key)
		append(&res.cookies, http.Cookie{
			name         = "session_key",
			value        = session_key,
			expires_gmt  = time.time_add(time.now(), time.Hour),
			max_age_secs = 3600,
			path         = "/",
			http_only    = false,
			same_site    = .Strict,
			secure       = false,
		})

		ok := db.exec_cmd(db.conn, "INSERT INTO sessions (key, created_at, last_accessed_at) VALUES ($1, NOW(), NOW()) ON CONFLICT DO NOTHING", session_key)
		if !ok {
			log.error("Could not create session")
			http.respond(res, http.Status.Internal_Server_Error)
			return
		}
	}

	session.key = session_key

	next := handler.next.(^http.Handler)
	next.handle(next, req, res)
}