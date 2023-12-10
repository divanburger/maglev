package session

import "core:crypto/sha3"
import "core:math/rand"
import "core:encoding/base64"
import "core:time"
import "core:log"
import "core:fmt"

import http "lib:odin-http"

import base "../base"
import db "../database"

Session :: struct {
	key: string,
	user_id: Maybe(int),
}

SessionState :: struct {
	session: Session,
	_loaded: bool,
	_exists: bool,
	_req: ^http.Request,
	_res: ^http.Response,
}

@thread_local
state: SessionState

generate_key :: proc() -> string {
	bytes := transmute([8]u8)rand.uint64()
	hashed_bytes := sha3.hash_bytes_256(bytes[:])
	return base64.encode(hashed_bytes[:])
}

save :: proc() -> (ok: bool) {
	sess, exists := get() or_return
	if !exists do return

	user_id, user_ok := sess.user_id.?
	log.info(sess.key, user_id)
	if user_ok {
		ok = db.exec_cmd("UPDATE sessions SET user_id = $2, last_accessed_at = NOW() WHERE key = $1", sess.key, user_id)
	} else {
		ok = db.exec_cmd("UPDATE sessions SET user_id = NULL WHERE key = $1", sess.key)
	}
	return
}

sign_in :: proc(user_id: Maybe(int)) -> (ok: bool) {
	ensure_exists() or_return
	state.session.user_id = user_id
	return save()
}

sign_out :: proc() -> (ok: bool) {
	ok = true
	if state._exists do ok = db.exec_cmd("UPDATE sessions SET user_id = NULL WHERE key = $1", state.session.key)
	state.session.user_id = nil
	return
}

get_or_create :: proc(loc := #caller_location) -> (session: Session, ok: bool) {
	log.info("Load or create session...", location = loc)
	ensure_exists() or_return
	return state.session, true
}

get :: proc(loc := #caller_location) -> (session: Session, exists: bool, ok: bool) {
	log.info("Loading session...", location = loc)
	ensure_loaded() or_return
	return state.session, state._exists, true
}

ensure_loaded :: proc() -> (ok: bool) {
	if state._loaded {
		log.info("Already loaded session key")
		return true
	}

	state._loaded = true
	session_key, cookie_ok := http.request_cookie_get(state._req, "session_key")
	if cookie_ok {
		log.info("Request had key:", session_key)
		values, get_ok := db.exec_query("SELECT last_accessed_at, user_id FROM sessions WHERE key = $1", session_key)
		if get_ok && len(values) == 1 {
			last_accessed, last_access_ok := values[0]["last_accessed_at"].(time.Time)
			if !last_access_ok || time.since(last_accessed) > time.Hour {
				db.exec_cmd("UPDATE sessions SET last_accessed_at = NOW() WHERE key = $1", session_key)
			}
			user_id, user_id_ok := values[0]["user_id"].(int)
			state.session.key = session_key
			state.session.user_id = user_id_ok ? user_id : nil
			state._exists = true
			return state._exists
		}
	}
	
	log.info("No session key")
	return true
}

ensure_exists :: proc() -> (ok: bool) {
	ensure_loaded() or_return
	if state._exists do return true

	session_key := generate_key()
	log.info("Provided key:", session_key)
	append(&state._res.cookies, http.Cookie{
		name         = "session_key",
		value        = session_key,
		expires_gmt  = time.time_add(time.now(), 24 * time.Hour),
		max_age_secs = 86400,
		path         = "/",
		http_only    = false,
		same_site    = .Strict,
		secure       = false,
	})

	ok = db.exec_cmd("INSERT INTO sessions (key, created_at, last_accessed_at) VALUES ($1, NOW(), NOW()) ON CONFLICT DO NOTHING", session_key)
	if !ok {
		log.error("Could not create session")
		return false
	}

	state.session.key = session_key
	state._exists = true

	return true
}

handler :: proc(handler: ^http.Handler, req: ^http.Request, res: ^http.Response) {
	state = { _req = req, _res = res}
	next := handler.next.(^http.Handler)
	next.handle(next, req, res)
}