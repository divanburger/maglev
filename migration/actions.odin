package migration

import "core:log"
import "core:strings"

import db "../database"

Migration_Proc :: proc()

Migration_Entry :: struct {
	name: string,
	procedure: Migration_Proc,
}

Create_Table :: struct {
	name: string,
}

Drop_Table :: struct {
	name: string,
}

Add_Column :: struct {
	table_name: string,
	name: string,
	type: db.Database_Value_Type,
	default: Maybe(string),
	primary: bool,
	unique: bool,
	array: bool,
}

Set_Default :: struct {
	table_name: string,
	column: string,
	default: string,
}

Add_Index :: struct {
	table_name: string,
	columns: []string,
	unique: bool,
	name: Maybe(string),
}

Add_Primary_Key :: struct {
	table_name: string,
	columns: []string,
}

Add_Sequence :: struct {
	table_name: string,
	column: string,
	name: Maybe(string),
}

Action :: union {
	Create_Table,
	Drop_Table,
	Add_Column,
	Set_Default,
	Add_Index,
	Add_Primary_Key,
	Add_Sequence,
}

Migration :: struct {
	actions: [dynamic]Action,
}

Migration_State :: struct {
	migration: Migration,
	table_name: Maybe(string),
	rollback: bool,
}

@(thread_local)
migration_state: Migration_State	

create_table_begin :: proc(name: string, id := false) -> (creating: bool) {
	migration_state.table_name = name
	if (migration_state.rollback) {
		append(&migration_state.migration.actions, Drop_Table{name})
	} else {
		append(&migration_state.migration.actions, Create_Table{name})
		if id do add_column(name, "id", .Big_Int, primary = true, unique = true, sequence = true)
	}
	return !migration_state.rollback
}

create_table_end :: proc() {
	migration_state.table_name = nil
}

@(deferred_none=create_table_end)
create_table :: proc(name: string, id := false) -> (creating: bool) {
    return create_table_begin(name, id)
}

change_table_begin :: proc(name: string) -> (creating: bool) {
	migration_state.table_name = name
	return true
}

change_table_end :: proc() {
	migration_state.table_name = nil
}

@(deferred_none=change_table_end)
change_table :: proc(name: string) -> (creating: bool) {
    return change_table_begin(name)
}

add_column :: proc(table_name: string, name: string, type: db.Database_Value_Type, default: Maybe(string) = nil, primary := false, unique := false, index := false, sequence := false, array := false) {
	append(&migration_state.migration.actions, Add_Column{table_name, name, type, default, primary, unique, array})
	if !migration_state.rollback {
		if index && !unique {
			add_index(table_name, name)
		}
		if sequence {
			add_sequence(table_name, name)
			set_default(table_name, name, strings.concatenate([]string{"nextval('", sequence_name(table_name, name), "')"}))
		}
	}
}

column :: proc(name: string, type: db.Database_Value_Type, default: Maybe(string) = nil, primary := false, unique := false, index:= false, sequence := false, array := false) {
	table_name, ok := migration_state.table_name.(string)
	if !ok do panic("Must be called within a create_table call")
	add_column(table_name, name, type, default, primary, unique, index, sequence, array)
}

add_index_multi :: proc(table_name: string, columns: []string, unique : = false, name: Maybe(string) = nil) {
	columns_copy := make([]string, len(columns))
	copy(columns_copy, columns)
	append(&migration_state.migration.actions, Add_Index{table_name, columns_copy, unique, name})
}

add_index_single :: proc(table_name: string, column: string, unique := false, name: Maybe(string) = nil) {
	columns_copy := make([]string, 1)
	columns_copy[0]= column
	append(&migration_state.migration.actions, Add_Index{table_name, columns_copy, unique, name})
}

add_index :: proc{
	add_index_multi,
	add_index_single,
}

index_multi :: proc(columns: []string, unique: bool = false, name: Maybe(string) = nil) {
	table_name, ok := migration_state.table_name.(string)
	if !ok do panic("Must be called within a create_table call")
	add_index_multi(table_name, columns, unique, name)
}

index_single :: proc(column: string, unique: bool = false, name: Maybe(string) = nil) {
	table_name, ok := migration_state.table_name.(string)
	if !ok do panic("Must be called within a create_table call")
	add_index_single(table_name, column, unique, name)
}

index :: proc{
	index_multi,
	index_single,
}

add_sequence :: proc(table_name: string, column: string, name: Maybe(string) = nil) {
	append(&migration_state.migration.actions, Add_Sequence{table_name, column, name})
}

sequence :: proc(column: string, name: Maybe(string) = nil) {
	table_name, ok := migration_state.table_name.(string)
	if !ok do panic("Must be called within a create_table call")
	add_sequence(table_name, column, name)
}

set_default :: proc(table_name: string, column: string, default: string) {
	append(&migration_state.migration.actions, Set_Default{table_name, column, default})
}

default :: proc(column: string, default: string) {
	table_name, ok := migration_state.table_name.(string)
	if !ok do panic("Must be called within a create_table call")
	set_default(table_name, column, default)
}

reference :: proc(name: string, type: db.Database_Value_Type = .Big_Int, default: Maybe(string) = nil, index := true) {
	column(strings.concatenate([]string{name, "_id"}), type, default, index = index)
}

add_primary_key_multi :: proc(table_name: string, columns: []string) {
	columns_copy := make([]string, len(columns))
	copy(columns_copy, columns)
	append(&migration_state.migration.actions, Add_Primary_Key{table_name, columns_copy})
}

add_primary_key_single :: proc(table_name: string, column: string) {
	columns_copy := make([]string, 1)
	columns_copy[0]= column
	append(&migration_state.migration.actions, Add_Primary_Key{table_name, columns_copy})
}

add_primary_key :: proc{
	add_primary_key_multi,
	add_primary_key_single,
}

primary_key_multi :: proc(columns: []string) {
	table_name, ok := migration_state.table_name.(string)
	if !ok do panic("Must be called within a create_table call")
	add_primary_key_multi(table_name, columns)
}

primary_key_single :: proc(column: string) {
	table_name, ok := migration_state.table_name.(string)
	if !ok do panic("Must be called within a create_table call")
	add_primary_key_single(table_name, column)
}

primary_key :: proc{
	primary_key_multi,
	primary_key_single,
}