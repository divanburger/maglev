package database

Database_Value_Type :: enum {
	String,
	Big_Int,
	Integer,
	Boolean,
	Timestamp,
}

database_value_type_name: [Database_Value_Type]string = {
	.String = "varchar",
	.Big_Int = "bigint",
	.Integer = "integer",
	.Boolean = "boolean",
	.Timestamp = "timestamp",
}