package sqlite3

import b "./core"
import "core:strings"

DB :: struct {
	_db: ^b.Sqlite3,
}

Open_Flags :: b.Open_Flags
Result_Code :: b.Result_Code

DEFAULT_OPEN_FLAGS :: Open_Flags{.URI, .READWRITE}

// TODO: return err
open :: proc(uri: string, flags: Open_Flags = DEFAULT_OPEN_FLAGS) -> DB {
	db := DB{}
	uri_cstr := strings.unsafe_string_to_cstring(uri)
	b.open_v2(uri_cstr, &db._db, flags, nil)
	return db
}
