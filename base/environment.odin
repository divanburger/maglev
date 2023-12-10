package base

import "core:os"

_environment: string

environment :: proc() -> string {
	if len(_environment) > 0 do return _environment
	_environment := os.get_env("MAGLEV_ENV")
	if len(_environment) == 0 do _environment = "development"
	return _environment
}