package migration

import "core:strings"
import "core:log"

import db "../database"

sequence_name :: proc(table_name: string, column: string) -> string {
	return strings.concatenate({"sequence_", table_name, "_on_", column})
}

index_name :: proc(table_name: string, columns: []string) -> string {
	return strings.concatenate({"index_", table_name, "_on_", strings.join(columns, "_")})
}

execute_action :: proc(action: Action) -> (ok: bool) {
	switch act in action {
		case Create_Table:
			db.exec_cmd(strings.concatenate({"CREATE TABLE IF NOT EXISTS ", act.name, " ()"})) or_return
		case Drop_Table:
			db.exec_cmd(strings.concatenate({"DROP TABLE IF EXISTS ", act.name})) or_return
		case Add_Column:
			default := act.default.(string) or_else ""
			if len(default) > 0 do default = strings.concatenate({" DEFAULT ", default})
			primary := act.primary ? " PRIMARY KEY" : ""
			unique := act.unique ? " UNIQUE" : ""
			db_type := db.database_value_type_name[act.type]
			if act.array do db_type = strings.concatenate({db_type, "[]"})
			db.exec_cmd(strings.concatenate({"ALTER TABLE ", act.table_name, " ADD COLUMN IF NOT EXISTS ", act.name, " ", db_type, default, primary, unique})) or_return
		case Set_Default:
			db.exec_cmd(strings.concatenate({"ALTER TABLE ", act.table_name, " ALTER COLUMN ", act.column, " SET DEFAULT ", act.default})) or_return
		case Add_Index:
			name := act.name.(string) or_else index_name(act.table_name, act.columns)
			if len(name) > 63 do name = name[:63]
			db.exec_cmd(strings.concatenate({"CREATE ", (act.unique ? "UNIQUE " : ""), "INDEX IF NOT EXISTS ", name, " ON ", act.table_name, " (", strings.join(act.columns, ", "), ")"})) or_return
		case Add_Primary_Key:
			db.exec_cmd(strings.concatenate({"ALTER TABLE ", act.table_name, " ADD PRIMARY KEY (", strings.join(act.columns, ", "), ")"})) or_return
		case Add_Sequence:
			name := act.name.(string) or_else sequence_name(act.table_name, act.column)
			if len(name) > 63 do name = name[:63]
			db.exec_cmd(strings.concatenate({"CREATE SEQUENCE IF NOT EXISTS ", name, " OWNED BY ", act.table_name, ".", act.column})) or_return
		case:
	}
	return true
}

migrate :: proc(name: string, p: Migration_Proc) -> (ok: bool) {
	db.ensure_connection()

	exists := db.exec_exist("SELECT 1 FROM migrations WHERE name = $1", name) or_return
	if exists do return true

	log.info("Migrating:", name)
	migration_state = {}
	p()
	for action in migration_state.migration.actions do execute_action(action) or_return

	db.exec_cmd("INSERT INTO migrations (name, created_at) VALUES ($1, NOW())", name) or_return
	return true
}

rollback :: proc(name: string, p: Migration_Proc) -> (ok: bool) {
	db.ensure_connection()
	db.exec_cmd("DELETE FROM migrations WHERE name = $1", name) or_return

	migration_state = {}
	migration_state.rollback = true
	p()
	#reverse for action in migration_state.migration.actions do execute_action(action) or_return

	return true
}