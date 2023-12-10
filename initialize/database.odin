package initialize

import db "../database"

setup_database_tables :: proc() {
	db.ensure_connection()
	db.exec_cmd("CREATE TABLE IF NOT EXISTS migrations (name varchar PRIMARY KEY)")
}