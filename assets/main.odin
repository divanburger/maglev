package assets

import "core:crypto/sha3"
import "core:path/filepath"
import "core:path/slashpath"
import "core:encoding/hex"
import "core:strings"
import "core:log"
import "core:os"

Asset :: struct {
	url: string,
	file_path: string,
	name: string,
	digest: string,
}

AssetRoot :: struct {
	name: string,
	url_prefix: string,
	file_prefix: string,
	by_name: map[string]^Asset,
	by_url: map[string]^Asset,
}

cdn_allow_origin: Maybe(string)
cdn_url_base: Maybe(string)
roots_by_name: map[string]^AssetRoot;
roots: [dynamic]^AssetRoot;

add_root :: proc(name: string, file_prefix: string, url_prefix: string) {
	root := new_clone(AssetRoot{name = name, file_prefix = file_prefix, url_prefix = url_prefix})
	roots_by_name[name] = root
	append(&roots, root)
}

lookup_by_name :: proc(root: string, name: string) -> (asset: ^Asset, ok: bool) {
	root := roots_by_name[root]
	asset, ok = root.by_name[name]
	if ok do return

	return lookup_by_root(root, name)
}

lookup_by_root :: proc(root: ^AssetRoot, name: string) -> (asset: ^Asset, ok: bool) {
	file_path := filepath.join([]string{root.file_prefix, name})
	file, err := os.open(file_path)
	if err != os.ERROR_NONE {
		log.error("Could not find asset: ", name, "->", file_path)
		return nil, false
	}
	defer os.close(file)

	hash_bytes := sha3.hash_224(file) or_return

	digest := string(hex.encode(hash_bytes[:8]))

	dir := slashpath.dir(name)
	base_name := slashpath.name(name)
	ext := slashpath.ext(name)
	url := slashpath.join([]string{root.url_prefix, dir, strings.concatenate([]string{base_name, "-", digest, ext})})
	{
		base, cdn_base_ok := cdn_url_base.?
		if cdn_base_ok do url = strings.concatenate([]string{base, url})
	}
	// log.info("Asset add:", url)

	ok = true
	asset = new_clone(Asset{ url = url, file_path = file_path, name = name, digest = digest })
	root.by_name[name] = asset
	root.by_url[url] = asset
	return
}

lookup :: proc{
	lookup_by_name,
	lookup_by_root
}

url :: proc(root, name: string) -> string {
	asset, ok := lookup(root, name)
	if !ok do return ""
	return asset.url
}