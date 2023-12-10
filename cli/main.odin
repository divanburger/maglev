package cli

import "core:os"
import "core:log"
import mr "lib:maglev/migration/runner"

process_commands :: proc() -> (executed_command: bool) {
	if len(os.args) > 1 {
		switch os.args[1] {
		case "db:migrate":
			mr.migrate()
		case "db:rollback":
			mr.rollback()
		case "db:drop":
			mr.drop()
		case "db:create":
			mr.create()
		case:
			log.error("Unknown command:", os.args[1])
		}
		return true
	}

	return false
}