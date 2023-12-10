package runner

import "core:log"

import m ".."
import db "../../database"

registered_migrations : []m.Migration_Entry

migrate :: proc() -> (ok: bool) {
	create() or_return

	for entry in registered_migrations {
		m.migrate(entry.name, entry.procedure) or_return
	}
	return true
}

rollback :: proc() -> (ok: bool) {
	db.ensure_connection()
	rows := db.exec_query("SELECT name FROM migrations ORDER BY name DESC LIMIT 1") or_return
	if len(rows) != 1 do return false
	name := rows[0]["name"].(string) or_return
	log.info(name)

	procedure: m.Migration_Proc
	for entry in registered_migrations {
		if entry.name == name do procedure = entry.procedure
	}

	return m.rollback(name, procedure)
}

create :: proc() -> (ok: bool) {
	db.ensure_connection()
	db.exec_cmd("CREATE SCHEMA IF NOT EXISTS public") or_return
	db.exec_cmd("CREATE TABLE IF NOT EXISTS migrations (name varchar PRIMARY KEY, created_at timestamp)") or_return
	return true
}

drop :: proc() -> (ok: bool) {
	db.ensure_connection()
	db.exec_cmd("DROP SCHEMA IF EXISTS public CASCADE") or_return
	return true
}