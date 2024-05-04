package base

import "core:log"
import "core:reflect"
import "core:runtime"
import "core:mem"
import "core:strings"
import "core:time"

to_struct :: proc($T: typeid, row: map[string]Value, allocator := context.allocator) -> (s: ^T, ok: bool) {
	s = new(T)
	ok = to_struct_ptr(s, row, allocator)
	return
}

to_struct_ptr :: proc(s: ^$T, row: map[string]Value, allocator := context.allocator) -> (ok: bool) {
	types := reflect.struct_field_types(T)
	offsets := reflect.struct_field_offsets(T)
	for name, i in reflect.struct_field_names(T) {
		// log.info(name)
		type := types[i]
		to_ptr := rawptr(uintptr(s) + uintptr(offsets[i]))
		#partial switch info in type.variant {
			case runtime.Type_Info_String:
				val := row[name].(string) or_else ""
				val = strings.clone(val, allocator)
				mem.copy(to_ptr, &val, type.size)
			case runtime.Type_Info_Integer:
				val := row[name].(int) or_else 0
				mem.copy(to_ptr, &val, type.size)
			case runtime.Type_Info_Boolean:
				val := row[name].(bool) or_else false
				// log.info(val)
				mem.copy(to_ptr, &val, type.size)
			case runtime.Type_Info_Named:
				named_type := type.variant.(runtime.Type_Info_Named)
				if named_type.name == "Time" {
					val := row[name].(time.Time) or_return
					mem.copy(to_ptr, &val, type.size)
				} else {
					val := row[strings.concatenate({name, "_id"})].(int) or_else 0
					mem.copy(to_ptr, &val, type.size)
				}
			case:
				log.error("Unsupported type", type, "for", name)
		}
	}
	return true
}