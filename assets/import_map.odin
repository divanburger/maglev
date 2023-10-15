package assets

import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:path/slashpath"
import "core:log"
import "core:encoding/json"

js_module_for_name :: proc(name: string) -> (module: string, ok: bool) {
	path := filepath.join([]string{"node_modules", name})
	package_file_path := filepath.join([]string{path, "package.json"})
	data := os.read_entire_file(package_file_path) or_return

	json_data, err := json.parse(data)
	if err != .None {
		log.error("Error parsing", package_file_path, err)
		return
	}

	base := json_data.(json.Object) or_return

	module_val, module_ok := base["module"]
	if module_ok do module, _ = base["module"].(string)

	return module, true
}

ImportMapState :: struct {
	imports: ^json.Object,
	js_root: ^AssetRoot,
	prefix: string,
}

build_import_map :: proc(root: string, node_modules_root: ^AssetRoot, js_root: ^AssetRoot) -> bool {
	data := os.read_entire_file("package.json") or_return

	json_data, err := json.parse(data)
	if err != .None {
		log.error("Error parsing package.json", err)
		return false
	}

	base := json_data.(json.Object) or_return
	deps_val := base["dependencies"] or_return
	deps := deps_val.(json.Object) or_return

	imports: json.Object

	// JS Dependencies
	if node_modules_root != nil {
		log.info("Building js dependencies...")
		for name, _ in deps {
			js_module, ok := js_module_for_name(name)
			if ok {
				if len(js_module) > 0 {
					module_path := slashpath.join([]string{name, js_module})
					asset, module_ok := lookup(node_modules_root, module_path)
					imports[name] = asset.url
				}
				path := strings.concatenate([]string{name, "/"})
				imports[path] = strings.concatenate([]string{slashpath.join([]string{root, path}), "/"})
			}
		}
	}

	// Own JS files
	if js_root != nil {
		log.info("Building own js files...")
		prefix := strings.concatenate([]string{filepath.join([]string{os.get_current_directory(), js_root.file_prefix}), "/"})
		state := ImportMapState{&imports, js_root, prefix}

		filepath.walk(js_root.file_prefix, proc(info: os.File_Info, in_err: os.Errno, user_data: rawptr) -> (err: os.Errno, skip_dir: bool) {
			state := cast(^ImportMapState)user_data
			if !info.is_dir && filepath.ext(info.name) == ".js" {
				name := strings.trim_prefix(info.fullpath, state.prefix)
				asset, ok := lookup(state.js_root, name)
				if ok do state.imports[name] = asset.url
			}
			return
		}, &state)
	}

	import_map: json.Object
	import_map["imports"] = imports
	import_map["scopes"] = json.Object{}

	import_map_bytes, marshal_err := json.marshal(import_map)
	if marshal_err != nil {
		log.error(marshal_err)
		return false
	}

	os.write_entire_file("importmap.json", import_map_bytes)
	return true
}