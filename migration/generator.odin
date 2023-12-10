package migration

import "core:path/filepath"
import "core:strings"
import "core:unicode"
import "core:os"
import "core:log"

build_all :: proc(force: bool = false) -> (ok: bool) {
	files, err := filepath.glob("./app/migrations/*.odin")
	if err != .None do return

	output_dir := filepath.join([]string{"generated"})
	os.make_directory(output_dir)

	output_filename := filepath.join([]string{output_dir, "migrations.odin"})
	result, err_out := os.open(output_filename, os.O_CREATE | os.O_TRUNC | os.O_WRONLY, 0o644)
	if err_out != os.ERROR_NONE {
		log.error("Could not open", output_filename, ": error", err_out)
		return false
	}
	defer os.close(result)

	os.write_string(result, `package generated

import m "../app/migrations"
import migration "lib:maglev/migration"

registered_migrations := [?]migration.Migration_Entry{
`)
	for file in files {
		name := filepath.short_stem(file)
		proc_name := name

		if unicode.is_digit(cast(rune)name[0]) {
			parts := strings.split_n(name, "_", 2)
			if len(parts) == 2 do proc_name = parts[1]
		}

		os.write_string(result, "\t{\"")
		os.write_string(result, name)
		os.write_string(result, `", m.`)
		os.write_string(result, proc_name)
		os.write_string(result, "},\n")
	}
	os.write_string(result, "}")

	return true
}