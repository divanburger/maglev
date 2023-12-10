package base

import "core:log"
import "core:reflect"
import "core:runtime"
import "core:mem"
import "core:strings"

to_struct :: proc($T: typeid, row: map[string]Value, allocator := context.allocator) -> (s: ^T, ok: bool) {
	s = new(T)
	types := reflect.struct_field_types(T)
	offsets := reflect.struct_field_offsets(T)
	for name, i in reflect.struct_field_names(T) {
		type := types[i]
		to_ptr := rawptr(uintptr(s) + uintptr(offsets[i]))
		#partial switch info in type.variant {
			case runtime.Type_Info_String:
				val := row[name].(string) or_return
				mem.copy(to_ptr, &val, type.size)
			case runtime.Type_Info_Integer:
				val := row[name].(int) or_return
				mem.copy(to_ptr, &val, type.size)
			case runtime.Type_Info_Named:
				val := row[strings.concatenate({name, "_id"})].(int) or_return
				mem.copy(to_ptr, &val, type.size)
			case:
				log.error("Unsupported type", type, "for", name)
		}
	}
	return s, true
}
