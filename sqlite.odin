package sqlite3

import b "./core"
import "core:c"
import "core:strings"

DB :: struct {
	_db: ^b.Sqlite3,
}

Open_Flags :: b.Open_Flags
Prepare_Flags :: b.Prepare_Flags
Result_Code :: b.Result_Code

DEFAULT_OPEN_FLAGS :: Open_Flags{.CREATE, .URI, .READWRITE, .WAL}

Null :: distinct struct {}

Value :: union #no_nil {
	i64,
	f64,
	string,
	[dynamic]u8,
	Null,
}

@(require_results)
open :: proc(uri: string, flags: Open_Flags = DEFAULT_OPEN_FLAGS) -> (DB, Result_Code) {
	db := DB{}
	uri_cstr := strings.clone_to_cstring(uri)
	res := b.open_v2(uri_cstr, &db._db, flags, nil)
	return db, res
}

close :: proc(db: DB) -> Result_Code {
	return b.close(db._db)
}

query :: proc(
	db: DB,
	sql: string,
	bindings: ..Value,
) -> (
	results: [dynamic][dynamic]Value,
	err: Result_Code,
) {
	cmd := transmute([^]u8)strings.clone_to_cstring(sql)
	stmt: ^b.Stmt

	b.prepare_v3(db._db, cmd, cast(c.int)len(sql), b.Prepare_Flags{}, &stmt, nil) or_return
	defer b.finalize(stmt)

	count := b.column_count(stmt)

	for binding, i in bindings {
		switch _bind in binding {
		case i64:
			b.bind_int64(stmt, c.int(i + 1), _bind) or_return
		case f64:
			b.bind_double(stmt, c.int(i + 1), c.double(_bind)) or_return
		case string:
			str := transmute([^]u8)strings.clone_to_cstring(_bind)
			b.bind_text(stmt, c.int(i + 1), str, c.int(len(_bind)), b.STATIC) or_return
		case [dynamic]u8:
		// TODO: bind BLOB
		case Null:
			b.bind_null(stmt, c.int(i + 1)) or_return
		}
	}

	for {
		step_res := b.step(stmt)

		if step_res == .DONE {
			break
		} else if step_res != .ROW {
			return results, step_res
		}

		row := [dynamic]Value{}
		for i: c.int = 0; i < count; i += 1 {
			ctype := b.column_type(stmt, i)
			switch (ctype) {
			case .TEXT:
				sb: strings.Builder
				strings.write_string(&sb, string(b.column_text(stmt, i)))
				val := strings.to_string(sb)
				append(&row, val)
			case .BLOB:
			// TODO: append BLOB

			// size := b.column_bytes(stmt, i)
			// bytes := b.column_blob(stmt, i)[:size]
			// append(&row, bytes)
			case .FLOAT:
				append(&row, f64(b.column_double(stmt, i)))
			case .INTEGER:
				val := i64(b.column_int64(stmt, i))
				append(&row, val)
			case .NULL:
				append(&row, Null{})
			}
		}

		append(&results, row)
	}

	return
}

// TODO: add a polymorphic variant with Prepare_Flags argument
