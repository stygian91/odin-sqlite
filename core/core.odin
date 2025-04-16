package sqlite3_core

import "core:c"
import "core:os"

when ODIN_OS == .Linux do foreign import sqlite {"system:sqlite3", "system:pthread"}
when ODIN_OS == .Darwin do foreign import sqlite {"system:sqlite3", "system:pthread"}

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
	exec :: proc(db: ^Sqlite3, sql: cstring, call: Exec_Callback, arg: rawptr, errmsg: ^cstring) -> Result_Code ---

	last_insert_rowid :: proc(db: ^Sqlite3) -> i64 ---
	changes :: proc(db: ^Sqlite3) -> c.int ---
	total_changes :: proc(db: ^Sqlite3) -> c.int ---

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

	bind_parameter_count :: proc (stmt: ^Stmt) -> c.int ---
	bind_parameter_index :: proc (stmt: ^Stmt, name: cstring) -> c.int ---
	bind_parameter_name :: proc (stmt: ^Stmt, n: c.int) -> cstring ---

	bind_int :: proc(stmt: ^Stmt, index: c.int, value: c.int) -> Result_Code ---
	bind_null :: proc(stmt: ^Stmt, index: c.int) -> Result_Code ---
	bind_int64 :: proc(stmt: ^Stmt, index: c.int, value: i64) -> Result_Code ---
	bind_double :: proc(stmt: ^Stmt, index: c.int, value: c.double) -> Result_Code ---
	bind_text :: proc(stmt: ^Stmt, index: c.int, first: ^c.char, byte_count: c.int, lifetime: uintptr) -> Result_Code ---
	bind_blob :: proc(stmt: ^Stmt, index: c.int, first: ^byte, byte_count: c.int, lifetime: uintptr) -> Result_Code ---

	stmt_readonly :: proc(stmt: ^Stmt) -> c.int ---
	stmt_isexplain :: proc(stmt: ^Stmt) -> c.int ---
	stmt_explain :: proc(stmt: ^Stmt, mode: Explain_Mode) -> Result_Code ---
	stmt_status :: proc (stmt: ^Stmt, counter_type: Stmt_Counter_Type, should_reset: c.int) -> c.int ---
	stmt_busy :: proc (stmt: ^Stmt) -> c.int ---

	trace_v2 :: proc(db: ^Sqlite3, mask: Trace_Flags, call: proc "c" (mask: Trace_Flag, x, y, z: rawptr) -> c.int, ctx: rawptr) -> Result_Code ---

	sql :: proc(stmt: ^Stmt) -> cstring ---
	expanded_sql :: proc(stmt: ^Stmt) -> cstring ---

	threadsafe :: proc () -> Threadsafe_Type ---
	libversion :: proc () -> cstring ---
	libversion_number :: proc () -> c.int ---
	sourceid :: proc () -> cstring ---
	limit :: proc (db: ^Sqlite3, category: Limit_Type, new_val: c.int) -> c.int ---
	db_config :: proc (db: ^Sqlite3, op: Db_Config_Type, #c_vararg args: ..any) -> Result_Code ---
}

Exec_Callback :: proc "c" (
	data: rawptr,
	nCol: c.int,
	colValues: [^]cstring,
	colNames: [^]cstring,
) -> Result_Code

Datatype :: enum {
	Integer = 1,
	Float   = 2,
	Text    = 3,
	Blob    = 4,
	Null    = 5,
}

Static :: uintptr(0)
Transient :: ~uintptr(0)

Trace_Flag :: enum {
	Stmt,
	Profile,
	Row,
	Close,
}

Trace_Flags :: bit_set[Trace_Flag]

Prepare_Flag :: enum {
	Persistent,
	Normalize,
	No_Vtab,
	Dont_Log,
}

Prepare_Flags :: bit_set[Prepare_Flag]

Open_Flag :: enum {
	Readonly, // Ok for sqlite3_open_v2()
	Readwrite, // Ok for sqlite3_open_v2()
	Create, // Ok for sqlite3_open_v2()
	Deleteonclose, // VFS only
	Exclusive, // VFS only
	Autoproxy, // VFS only
	Uri, // Ok for sqlite3_open_v2()
	Memory, // Ok for sqlite3_open_v2()
	Main_Db, // VFS only
	Temp_Db, // VFS only
	Transient_Db, // VFS only
	Main_Journal, // VFS only
	Temp_Journal, // VFS only
	Subjournal, // VFS only
	Super_Journal, // VFS only
	Nomutex, // Ok for sqlite3_open_v2()
	Fullmutex, // Ok for sqlite3_open_v2()
	Sharedcache, // Ok for sqlite3_open_v2()
	Privatecache, // Ok for sqlite3_open_v2()
	Wal, // VFS only
	Nofollow, // Ok for sqlite3_open_v2()
	Exrescode, // Extended result codes
}

Open_Flags :: bit_set[Open_Flag]

Explain_Mode :: enum c.int {
	Normal = 0,
	Explain = 1,
	Explain_Query_Plan = 2,
}

Stmt_Counter_Type :: enum c.int {
	Fullscan_Step = 1,
	Sort = 2,
	Autoindex = 3,
	Vm_Step = 4,
	Reprepare = 5,
	Run = 6,
	Filter_Miss = 7,
	Filter_Hit = 8,
	Memused = 99,
}

Threadsafe_Type :: enum c.int {
	Single = 0,
	Multi = 1,
	Serialized = 2,
}

Limit_Type :: enum c.int {
	Length = 0,
	Sql_Length = 1,
	Column = 2,
	Expr_Depth = 3,
	Compound_Select = 4,
	Vdbe_Op = 5,
	Function_Arg = 6,
	Attached = 7,
	Like_Pattern_Length = 8,
	Variable_Number = 9,
	Trigger_Depth = 10,
	Worker_Threads = 11,
}

Db_Config_Type :: enum c.int {
	Main_Db_Name = 1000,
	Lookaside = 1001,
	Enable_Fkey = 1002,
	Enable_Trigger = 1003,
	Enable_Fts3_Tokenizer = 1004,
	Enable_Load_Extension = 1005,
	No_Ckpt_On_Close = 1006,
	Enable_Qpsg = 1007,
	Trigger_eqp = 1008,
	Reset_Database = 1009,
	Defensive = 1010,
	Writable_Schema = 1011,
	Legacy_Alter_Table = 1012,
	Dqs_Dml = 1013,
	Dqs_Ddl = 1014,
	Enable_View = 1015,
	Legacy_File_Format = 1016,
	Trusted_Schema = 1017,
	Max = 1017,
}

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
	Ok         = 0, // Successful result
	Error      = 1, // Generic error
	Internal   = 2, // Internal logic error in SQLite
	Perm       = 3, // Access permission denied
	Abort      = 4, // Callback routine requested an abort
	Busy       = 5, // The database file is locked
	Locked     = 6, // A table in the database is locked
	Nomem      = 7, // A malloc() failed
	Readonly   = 8, // Attempt to write a readonly database
	Interrupt  = 9, // Operation terminated by sqlite3_interrupt(
	Ioerr      = 10, // Some kind of disk I/O error occurred
	Corrupt    = 11, // The database disk image is malformed
	Notfound   = 12, // Unknown opcode in sqlite3_file_control()
	Full       = 13, // Insertion failed because database is full
	Cantopen   = 14, // Unable to open the database file
	Protocol   = 15, // Database lock protocol error
	Empty      = 16, // Internal use only
	Schema     = 17, // The database schema changed
	Toobig     = 18, // String or BLOB exceeds size limit
	Constraint = 19, // Abort due to constraint violation
	Mismatch   = 20, // Data type mismatch
	Misuse     = 21, // Library used incorrectly
	Nolfs      = 22, // Uses OS features not supported on host
	Auth       = 23, // Authorization denied
	Format     = 24, // Not used
	Range      = 25, // 2nd parameter to sqlite3_bind out of range
	Notadb     = 26, // File opened that is not a database file
	Notice     = 27, // Notifications from sqlite3_log()
	Warning    = 28, // Warnings from sqlite3_log()
	Row        = 100, // sqlite3_step() has another row ready
	Done       = 101, // sqlite3_step() has finished executing
}
