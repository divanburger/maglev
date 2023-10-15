package database

import "core:log"

import http "lib:odin-http"
import "lib:postgres"

DBInfo :: struct {
	user_name: string,
	password: string,
	db_name: string,
	set: bool,
}

@private
info: DBInfo

@thread_local
conn: ^postgres.Conn

setup :: proc(conn_info: DBInfo) {
	info = info
	info.set = true
}

check_connection :: proc() -> (success: bool) {
	if conn != nil do return true

	conn = postgres.connectdb("dbname=oweb user=oweb password=oweb")
	if conn == nil {
		log.error("Could not connect to database!")
		return false
	}

	if status := postgres.status(conn); status != postgres.ConnStatusType.OK {
		log.error("Error connecting to database!", postgres.errorMessage(conn))
		return false
	}

	log.info("Opened database connection")
	return true
}

handler :: proc(handler: ^http.Handler, req: ^http.Request, res: ^http.Response) {
	if check_connection() {
		next := handler.next.(^http.Handler)
		next.handle(next, req, res)
	}
}