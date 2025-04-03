package sqlite3

import b "./core"
import "core:c"
import "core:strings"

DB :: struct {
	_db: ^b.Sqlite3,
}

Stmt :: b.Stmt
Open_Flags :: b.Open_Flags
Prepare_Flags :: b.Prepare_Flags
Result_Code :: b.Result_Code

DEFAULT_OPEN_FLAGS :: Open_Flags{.CREATE, .URI, .READWRITE}

Null :: distinct struct {}

Value :: union #no_nil {
	Null,
	i64,
	f64,
	string,
	[dynamic]u8,
}

Lifetime :: enum uintptr {
	Static    = b.STATIC,
	Transient = b.TRANSIENT,
}

Exec_Callback_Proc :: #type proc(row_idx: int, col_idx: int, col_name: string, value: Value)

@(require_results)
open :: proc(uri: string, flags: Open_Flags = DEFAULT_OPEN_FLAGS) -> (DB, Result_Code) {
	db := DB{}
	uri_cstr := strings.clone_to_cstring(uri)
	defer delete(uri_cstr)
	res := b.open_v2(uri_cstr, &db._db, flags, nil)

	if res == .OK {
		enable_wal(db)
	}

	return db, res
}

close :: proc(db: DB) -> Result_Code {
	return b.close(db._db)
}

@(require_results)
exec_discard :: proc(db: DB, sql: string, bindings: ..Value) -> (err: Result_Code) {
	cmd := transmute([^]u8)strings.clone_to_cstring(sql)
	defer free(cmd)

	stmt: ^b.Stmt
	b.prepare_v3(db._db, cmd, cast(c.int)len(sql), Prepare_Flags{}, &stmt, nil) or_return
	defer b.finalize(stmt)

	bind_parameters(stmt, .Static, ..bindings) or_return

	return stmt_resuts_discard(stmt)
}

@(require_results)
exec_fetch :: proc(
	db: DB,
	sql: string,
	bindings: ..Value,
) -> (
	results: [dynamic][dynamic]Value,
	err: Result_Code,
) {
	cmd := transmute([^]u8)strings.clone_to_cstring(sql)
	defer free(cmd)

	stmt: ^b.Stmt
	b.prepare_v3(db._db, cmd, cast(c.int)len(sql), Prepare_Flags{}, &stmt, nil) or_return
	defer b.finalize(stmt)

	bind_parameters(stmt, .Static, ..bindings) or_return

	return stmt_results_fetch(stmt)
}

@(require_results)
exec_callback :: proc(
	db: DB,
	sql: string,
	cb: Exec_Callback_Proc,
	bindings: ..Value,
) -> (
	err: Result_Code,
) {
	cmd := transmute([^]u8)strings.clone_to_cstring(sql)
	defer free(cmd)

	stmt: ^b.Stmt
	b.prepare_v3(db._db, cmd, cast(c.int)len(sql), Prepare_Flags{}, &stmt, nil) or_return
	defer b.finalize(stmt)

	bind_parameters(stmt, .Static, ..bindings) or_return

	return stmt_results_loop(stmt, cb)
}

@(require_results)
bind_parameters :: proc(stmt: ^Stmt, lifetime: Lifetime, bindings: ..Value) -> (err: Result_Code) {
	lifetime := transmute(uintptr)lifetime

	for binding, i in bindings {
		idx := c.int(i + 1)

		switch bind in binding {
		case i64:
			b.bind_int64(stmt, idx, bind) or_return
		case f64:
			b.bind_double(stmt, idx, c.double(bind)) or_return
		case string:
			str := transmute([^]u8)strings.clone_to_cstring(bind)
			b.bind_text(stmt, idx, str, c.int(len(bind)), lifetime) or_return
		case [dynamic]u8:
			first := raw_data(bind)
			b.bind_blob(stmt, idx, first, c.int(len(bind)), lifetime) or_return
		case Null:
			b.bind_null(stmt, idx) or_return
		}
	}

	return .OK
}

@(require_results)
stmt_results_fetch :: proc(stmt: ^Stmt) -> (results: [dynamic][dynamic]Value, err: Result_Code) {
	count := b.column_count(stmt)

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
			case .Text:
				sb: strings.Builder
				strings.write_string(&sb, string(b.column_text(stmt, i)))
				val := strings.to_string(sb)
				append(&row, val)
			case .Blob:
				size := b.column_bytes(stmt, i)
				ptr_byte := b.column_blob(stmt, i)
				str := strings.string_from_ptr(ptr_byte, int(size))
				append_elem(&row, dynu8_from_str(str))
			case .Float:
				append(&row, f64(b.column_double(stmt, i)))
			case .Integer:
				val := i64(b.column_int64(stmt, i))
				append(&row, val)
			case .Null:
				append(&row, Null{})
			}
		}

		append(&results, row)
	}

	return
}

stmt_resuts_discard :: proc(stmt: ^Stmt) -> (err: Result_Code) {
	for {
		step_res := b.step(stmt)

		if step_res == .DONE {
			break
		} else if step_res != .ROW {
			return step_res
		}
	}

	return .OK
}

stmt_results_loop :: proc(stmt: ^Stmt, cb: Exec_Callback_Proc) -> (err: Result_Code) {
	count := b.column_count(stmt)
	row_idx := 0

	for {
		step_res := b.step(stmt)

		if step_res == .DONE {
			return
		} else if step_res != .ROW {
			return step_res
		}

		for i: c.int = 0; i < count; i += 1 {
			ctype := b.column_type(stmt, i)
			cname := string(b.column_name(stmt, i))

			switch (ctype) {
			case .Text:
				sb: strings.Builder
				strings.write_string(&sb, string(b.column_text(stmt, i)))
				val := strings.to_string(sb)
				defer delete(val)
				cb(row_idx, int(i), cname, val)
			case .Blob:
				size := b.column_bytes(stmt, i)
				ptr_byte := b.column_blob(stmt, i)
				str := strings.string_from_ptr(ptr_byte, int(size))
				val := dynu8_from_str(str)
				defer delete(val)
				cb(row_idx, int(i), cname, val)
			case .Float:
				cb(row_idx, int(i), cname, f64(b.column_double(stmt, i)))
			case .Integer:
				cb(row_idx, int(i), cname, i64(b.column_int64(stmt, i)))
			case .Null:
				cb(row_idx, int(i), cname, Null{})
			}
		}

		row_idx += 1
	}
}

enable_wal :: proc(db: DB) -> bool {
	res, exec_err := exec_fetch(db, "PRAGMA journal_mode=WAL;")
	defer results_free(res)

	if exec_err != .OK {
		return false
	}

	if len(res) == 0 || len(res[0]) == 0 {
		return false
	}

	#partial switch mode in res[0][0] {
	case string:
		return mode == "wal"
	case:
		return false
	}
}

results_free :: proc(results: [dynamic][dynamic]Value) {
	for res in results {
		for el in res {
			#partial switch e in el {
			case string:
				delete(e)
			case [dynamic]u8:
				delete(e)
			}
		}

		delete(res)
	}

	delete(results)
}

@(private)
dynu8_from_str :: proc(str: string) -> [dynamic]u8 {
	sb: strings.Builder
	strings.write_string(&sb, str)
	return sb.buf
}
