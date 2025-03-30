package sqlite3

import b "./core"
import "core:strings"

DB :: struct {
	_db: ^b.Sqlite3,
}

Open_Flags :: b.Open_Flags
Result_Code :: b.Result_Code

DEFAULT_OPEN_FLAGS :: Open_Flags{.URI, .READWRITE, .WAL}

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
