package cli

import "core:os"
import "core:log"

import "../template"
import "../migration"

main :: proc() {
	context.logger = log.create_console_logger(.Info)
	
	if len(os.args) > 1 {
		switch os.args[1] {
		case:
			log.error("Unknown command:", os.args[1])
		}
	} else {
		log.info("Building migration list...")
		ok := migration.build_all()
		if !ok {
			log.error("Error building migration list")
		}

		log.info("Building partials...")
		ok = template.build_all(force = false)
		if !ok {
			log.error("Error building partials")
		}

		log.info("Completed build")
	}
}