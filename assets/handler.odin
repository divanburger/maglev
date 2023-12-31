package assets

import "core:path/filepath"
import "core:strings"
import "core:log"

import http "lib:odin-http"

create_router_with_fallback :: proc(fallback: http.Handler) -> (router: ^http.Router) {
	router = new(http.Router)
	http.router_init(router)
	add_routes(router)
	http.route_all(router, "(.*)", fallback)
	return
}

create_router_none :: proc() -> (router: ^http.Router) {
	router = new(http.Router)
	http.router_init(router)
	add_routes(router)
	return
}

create_router :: proc{
	create_router_with_fallback,
	create_router_none,
}

add_routes :: proc(router: ^http.Router) {
	for root in roots {
		matcher := strings.concatenate([]string{"(", root.url_prefix, ".*)"})
		http.route_get(router, matcher, http.handler(handler))
	}
}

handler :: proc(req: ^http.Request, r: ^http.Response) {
	request := req.url_params[0]
	root: ^AssetRoot
	for cur_root in roots {
		if strings.has_prefix(request, cur_root.url_prefix) {
			root = cur_root
			break
		}
	}

	if root == nil {
		http.respond(r, http.Status.Not_Found)
		return
	}

	// Detect path traversal attacks.
	req_clean := filepath.clean(request, context.temp_allocator)
	base_clean := filepath.clean(root.url_prefix, context.temp_allocator)
	if !strings.has_prefix(req_clean, base_clean) {
		http.respond(r, http.Status.Not_Found)	
		return
	}

	asset, ok := root.by_url[req_clean]
	if !ok {
		suffix := strings.trim_prefix(req_clean, base_clean)
		index_dash := strings.last_index(suffix, "-")
		index_dot := strings.last_index(suffix, ".")
		if index_dash < 0 || index_dot < index_dash {
			http.respond(r, http.Status.Not_Found)
			return
		}

		name := strings.concatenate([]string{suffix[:index_dash], suffix[index_dot:]})
		asset, ok = lookup(root.name, name)
		if !ok {
			http.respond(r, http.Status.Not_Found)
			return
		}
	}

	http.headers_set(&r.headers, "cache-control", "public, max-age=31556952, immutable")
	{
		origin, has_origin := http.headers_get(req.headers, "origin")
		log.info("Origin:", origin)
		if has_origin {
			for allowed_origin in cdn_allow_origin {
				log.info("Allowed origin:", allowed_origin)
				if allowed_origin == origin {
					log.info("Chosen origin:", allowed_origin)
					http.headers_set(&r.headers, "access-control-allow-origin", allowed_origin)
				}
			}
		}
	}
	http.respond_file(r, asset.file_path)
}