package sqlite3_core

import "core:c"
import "core:os"

// when os.OS == "windows" do foreign import sqlite { "sqlite3.lib" }
// do we need to import pthread and dl? 
// when ODIN_OS == .Linux do foreign import sqlite { "sqlite3.a", "system:pthread", "system:dl" }
// when ODIN_OS == .Darwin do foreign import sqlite { "sqlite3.a", "system:pthread", "system:dl" }

when ODIN_OS == .Linux do foreign import sqlite "system:libsqlite3.a"

@(default_calling_convention = "c", link_prefix = "sqlite3_")
foreign sqlite {
	// TODO: utf16 versions of functions

	open :: proc(filename: cstring, ppDb: ^^Sqlite3) -> Result_Code ---
	open_v2 :: proc(filename: cstring, ppDb: ^^Sqlite3, flags: Open_Flags, zVfs: cstring) -> Result_Code ---

	close :: proc(db: ^Sqlite3) -> Result_Code ---
	close_v2 :: proc(db: ^Sqlite3) -> Result_Code ---

	prepare :: proc(db: ^Sqlite3, zSql: ^c.char, nByte: c.int, ppStmt: ^^Stmt, pzTail: ^cstring) -> Legacy_Result_Code ---
	prepare_v2 :: proc(db: ^Sqlite3, zSql: ^c.char, nByte: c.int, ppStmt: ^^Stmt, pzTail: ^cstring) -> Result_Code ---
	prepare_v3 :: proc(db: ^Sqlite3, zSql: ^c.char, nByte: c.int, prepFlags: Prepare_Flags, ppStmt: ^^Stmt, pzTail: ^cstring) -> Result_Code ---

	step :: proc(stmt: ^Stmt) -> Result_Code ---
	finalize :: proc(stmt: ^Stmt) -> Result_Code ---
	exec :: proc(db: ^Sqlite3, sql: cstring, call: Exec_Callback, arg: rawptr, errmsg: [^]c.char) -> Result_Code ---

	last_insert_rowid :: proc(db: ^Sqlite3) -> i64 ---

	column_count :: proc(stmt: ^Stmt) -> c.int ---

	column_name :: proc(stmt: ^Stmt, i_col: c.int) -> cstring ---
	column_type :: proc(stmt: ^Stmt, i_col: c.int) -> Datatype ---
	column_decltype :: proc(stmt: ^Stmt, i_col: c.int) -> cstring ---
	column_bytes :: proc(stmt: ^Stmt, i_col: c.int) -> c.int ---

	column_blob :: proc(stmt: ^Stmt, i_col: c.int) -> ^byte ---
	column_text :: proc(stmt: ^Stmt, i_col: c.int) -> cstring ---
	column_int :: proc(stmt: ^Stmt, i_col: c.int) -> c.int ---
	column_int64 :: proc(stmt: ^Stmt, i_col: c.int) -> c.int64_t ---
	column_double :: proc(stmt: ^Stmt, i_col: c.int) -> c.double ---

	errcode :: proc(db: ^Sqlite3) -> c.int ---
	extended_errcode :: proc(db: ^Sqlite3) -> c.int ---
	errmsg :: proc(db: ^Sqlite3) -> cstring ---

	reset :: proc(stmt: ^Stmt) -> Result_Code ---
	clear_bindings :: proc(stmt: ^Stmt) -> Result_Code ---

	bind_int :: proc(stmt: ^Stmt, index: c.int, value: c.int) -> Result_Code ---
	bind_null :: proc(stmt: ^Stmt, index: c.int) -> Result_Code ---
	bind_int64 :: proc(stmt: ^Stmt, index: c.int, value: i64) -> Result_Code ---
	bind_double :: proc(stmt: ^Stmt, index: c.int, value: c.double) -> Result_Code ---
	bind_text :: proc(stmt: ^Stmt, index: c.int, first: ^c.char, byte_count: c.int, lifetime: uintptr) -> Result_Code --- // lifetime: proc "c" (data: rawptr),
	bind_blob :: proc(stmt: ^Stmt, index: c.int, first: ^byte, byte_count: c.int, lifetime: uintptr) -> Result_Code ---

	trace_v2 :: proc(db: ^Sqlite3, mask: Trace_Flags, call: proc "c" (mask: Trace_Flag, x, y, z: rawptr) -> c.int, ctx: rawptr) -> Result_Code ---

	sql :: proc(stmt: ^Stmt) -> cstring ---
	expanded_sql :: proc(stmt: ^Stmt) -> cstring ---
}

Exec_Callback :: proc "c" (
	data: rawptr,
	nCol: c.int,
	colValues: [^]cstring,
	colNames: [^]cstring,
) -> Result_Code

Datatype :: enum {
	INTEGER = 1,
	FLOAT   = 2,
	TEXT    = 3,
	BLOB    = 4,
	NULL    = 5,
}

STATIC :: uintptr(0)
TRANSIENT :: ~uintptr(0)

Trace_Flag :: enum {
	STMT,
	PROFILE,
	ROW,
	CLOSE,
}

Trace_Flags :: bit_set[Trace_Flag]

Prepare_Flag :: enum {
	PERSISTENT,
	NORMALIZE,
	NO_VTAB,
	DONT_LOG,
}

Prepare_Flags :: bit_set[Prepare_Flag]

Open_Flag :: enum {
	READONLY, // Ok for sqlite3_open_v2()
	READWRITE, // Ok for sqlite3_open_v2()
	CREATE, // Ok for sqlite3_open_v2()
	DELETEONCLOSE, // VFS only
	EXCLUSIVE, // VFS only
	AUTOPROXY, // VFS only
	URI, // Ok for sqlite3_open_v2()
	MEMORY, // Ok for sqlite3_open_v2()
	MAIN_DB, // VFS only
	TEMP_DB, // VFS only
	TRANSIENT_DB, // VFS only
	MAIN_JOURNAL, // VFS only
	TEMP_JOURNAL, // VFS only
	SUBJOURNAL, // VFS only
	SUPER_JOURNAL, // VFS only
	NOMUTEX, // Ok for sqlite3_open_v2()
	FULLMUTEX, // Ok for sqlite3_open_v2()
	SHAREDCACHE, // Ok for sqlite3_open_v2()
	PRIVATECACHE, // Ok for sqlite3_open_v2()
	WAL, // VFS only
	NOFOLLOW, // Ok for sqlite3_open_v2()
	EXRESCODE, // Extended result codes
}

Open_Flags :: bit_set[Open_Flag]

Stmt :: struct {}

LIMIT_LENGTH :: 0
LIMIT_SQL_LENGTH :: 1
LIMIT_COLUMN :: 2
LIMIT_EXPR_DEPTH :: 3
LIMIT_COMPOUND_SELECT :: 4
LIMIT_VDBE_OP :: 5
LIMIT_FUNCTION_ARG :: 6
LIMIT_ATTACHED :: 7
LIMIT_LIKE_PATTERN_LENGTH :: 8
LIMIT_VARIABLE_NUMBER :: 9
LIMIT_TRIGGER_DEPTH :: 10
LIMIT_WORKER_THREADS :: 11
N_LIMIT :: LIMIT_WORKER_THREADS + 1

Vfs :: struct {}

Vdbe :: struct {}

Coll_Seq :: struct {}

Mutex :: struct {}

Db :: struct {}

Sqlite3 :: struct {
	pVfs:                   ^Vfs, /* OS Interface */
	pVdbe:                  ^Vdbe, /* List of active virtual machines */
	pDfltColl:              ^Coll_Seq, /* BINARY collseq for the database encoding */
	mutex:                  ^Mutex, /* Connection mutex */
	aDb:                    ^Db, /* All backends */
	nDb:                    c.int, /* Number of backends currently in use */
	mDbFlags:               u32, /* flags recording c.internal state */
	flags:                  u64, /* flags settable by pragmas. See below */
	lastRowid:              i64, /* ROWID of most recent insert (see above) */
	szMmap:                 i64, /* Default mmap_size setting */
	nSchemaLock:            u32, /* Do not reset the schema when non-zero */
	openFlags:              c.uint, /* Flags passed to sqlite3_vfs.xOpen() */
	errCode:                c.int, /* Most recent error code (SQLITE_*) */
	errMask:                c.int, /* & result codes with this before returning */
	iSysErrno:              c.int, /* Errno value from last system error */
	dbOptFlags:             u32, /* Flags to enable/disable optimizations */
	enc:                    u8, /* Text encoding */
	autoCommit:             u8, /* The auto-commit flag. */
	temp_store:             u8, /* 1: file 2: memory 0: default */
	mallocFailed:           u8, /* True if we have seen a malloc failure */
	bBenignMalloc:          u8, /* Do not require OOMs if true */
	dfltLockMode:           u8, /* Default locking-mode for attached dbs */
	nextAutovac:            c.char, /* Autovac setting after VACUUM if >=0 */
	suppressErr:            u8, /* Do not issue error messages if true */
	vtabOnConflict:         u8, /* Value to return for s3_vtab_on_conflict() */
	isTransactionSavepoint: u8, /* True if the outermost savepoc.int is a TS */
	mTrace:                 u8, /* zero or more SQLITE_TRACE flags */
	noSharedCache:          u8, /* True if no shared-cache backends */
	nSqlExec:               u8, /* Number of pending OP_SqlExec opcodes */
	nextPagesize:           c.int, /* Pagesize after VACUUM if >0 */
	magic:                  u32, /* Magic number for detect library misuse */
	nChange:                c.int, /* Value returned by sqlite3_changes() */
	nTotalChange:           c.int, /* Value returned by sqlite3_total_changes() */
	aLimit:                 [N_LIMIT]c.int, /* Limits */
	nMaxSorterMmap:         c.int, /* Maximum size of regions mapped by sorter */
	init:                   struct {
		/* Information used during initialization */
		newTnum:       Pgno, /* Rootpage of table being initialized */
		iDb:           u8, /* Which db file is being initialized */
		busy:          u8, /* TRUE if currently initializing */
		orphanTrigger: u8, /* Last statement is orphaned TEMP trigger */
		imposterTable: u8, /* Building an imposter table */
		reopenMemdb:   u8, /* ATTACH is really a reopen using MemDB */
		azInit:        ^^u8, /* "type", "name", and "tbl_name" columns */
	},
	nVdbeActive:            c.int, /* Number of VDBEs currently running */
	nVdbeRead:              c.int, /* Number of active VDBEs that read or write */
	nVdbeWrite:             c.int, /* Number of active VDBEs that read and write */
	nVdbeExec:              c.int, /* Number of nested calls to VdbeExec() */
	nVDestroy:              c.int, /* Number of active OP_VDestroy operations */
	nExtension:             c.int, /* Number of loaded extensions */
	aExtension:             ^^rawptr, /* Array of shared library handles */
}

Pgno :: struct {}

Legacy_Result_Code :: enum c.int {
	OK    = 0, // Successful result
	ERROR = 1, // Generic error
}

Result_Code :: enum c.int {
	OK         = 0, // Successful result
	ERROR      = 1, // Generic error
	INTERNAL   = 2, // Internal logic error in SQLite
	PERM       = 3, // Access permission denied
	ABORT      = 4, // Callback routine requested an abort
	BUSY       = 5, // The database file is locked
	LOCKED     = 6, // A table in the database is locked
	NOMEM      = 7, // A malloc() failed
	READONLY   = 8, // Attempt to write a readonly database
	INTERRUPT  = 9, // Operation terminated by sqlite3_interrupt(
	IOERR      = 10, // Some kind of disk I/O error occurred
	CORRUPT    = 11, // The database disk image is malformed
	NOTFOUND   = 12, // Unknown opcode in sqlite3_file_control()
	FULL       = 13, // Insertion failed because database is full
	CANTOPEN   = 14, // Unable to open the database file
	PROTOCOL   = 15, // Database lock protocol error
	EMPTY      = 16, // Internal use only
	SCHEMA     = 17, // The database schema changed
	TOOBIG     = 18, // String or BLOB exceeds size limit
	CONSTRAINT = 19, // Abort due to constraint violation
	MISMATCH   = 20, // Data type mismatch
	MISUSE     = 21, // Library used incorrectly
	NOLFS      = 22, // Uses OS features not supported on host
	AUTH       = 23, // Authorization denied
	FORMAT     = 24, // Not used
	RANGE      = 25, // 2nd parameter to sqlite3_bind out of range
	NOTADB     = 26, // File opened that is not a database file
	NOTICE     = 27, // Notifications from sqlite3_log()
	WARNING    = 28, // Warnings from sqlite3_log()
	ROW        = 100, // sqlite3_step() has another row ready
	DONE       = 101, // sqlite3_step() has finished executing
}
