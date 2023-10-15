package template

import "core:os"
import "core:log"
import "core:strings"
import "core:time"
import "core:path/filepath"

build_all :: proc(force: bool = false) -> (ok: bool) {
	files, err := filepath.glob("partials/*.erb")
	if err != .None do return

	for file in files {
		source_info, source_err := os.stat(file)
		if source_err != os.ERROR_NONE {
			log.error(source_err, file)
			return
		}

		main_name := filepath.short_stem(file)
		new_file := strings.concatenate([]string{main_name, ".erb.odin"})
		new_file_path := filepath.join([]string{"app", "partials", new_file})

		if !force {
			generated_info, generated_err := os.stat(new_file_path)
			if generated_err == os.ERROR_NONE {
				since := time.diff(generated_info.modification_time, source_info.modification_time)
				if since < 0 do continue
			}
		}

		log.info("Generate", file)
		ok := parse_template(file, new_file_path, main_name)
		if !ok do return
	}

	return true
}
