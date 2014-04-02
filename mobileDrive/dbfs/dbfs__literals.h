#define QUOTE(str...) #str

// Note: only single statements are currently supported by the DBFS code
// If you want to separate statements with semicolons, you'll need to:
// allocate an array of statements and loop the creation and destruction.

// but init is special
const char *sql_fs2_init = QUOTE(
    /* *why* is this not the default yet? */
    PRAGMA foreign_keys = ON;

    CREATE TABLE IF NOT EXISTS dirs_v2
    (
        in_dir INTEGER REFERENCES dirs_v2(dir_handle) ON DELETE CASCADE ON UPDATE RESTRICT,
        dir_name TEXT NOT NULL, //CHECK(instr(dir_name, '/') == length(dir_name)),
        dir_handle INTEGER PRIMARY KEY,

        //CHECK(in_dir IS NOT NULL OR dir_name == '/'),
        //CHECK(dir_name != '/' OR dir_handle == 0),
        UNIQUE(in_dir, dir_name)
    );

    CREATE TABLE IF NOT EXISTS files_v2
    (
        in_dir INTEGER NOT NULL REFERENCES dirs_v2(dir_handle) ON DELETE CASCADE ON UPDATE RESTRICT,
        file_name TEXT NOT NULL, //CHECK(instr(file_name, '/') == 0),
        file_timestamp INTEGER,
        file_contents BLOB,

        PRIMARY KEY(in_dir, file_name)
    );

    /* root dir needs to be inserted specially */
    INSERT OR IGNORE INTO dirs_v2
    VALUES (NULL, '/', 0);
);

const char *sql_fs2_indir = QUOTE(
    SELECT dir_handle
    FROM dirs_v2
    WHERE in_dir = :indir AND dir_name = :name;
);

const char *sql_fs2_mkd1 = QUOTE(
    INSERT INTO dirs_v2
    VALUES (:indir, :name, NULL);
);

const char *sql_fs2_rmd1 = QUOTE(
    DELETE FROM dirs_v2
    WHERE in_dir == :indir AND dir_name == :name;
);

const char *sql_fs2_mvd1 = QUOTE(
    UPDATE dirs_v2
    SET in_dir = :to_dir, dir_name = :to_name
    WHERE in_dir = :from_dir AND dir_name = :from_name;
);

const char *sql_fs2_lsd1 = QUOTE(
    SELECT dir_name
    FROM dirs_v2
    WHERE in_dir = :indir;
);

const char *sql_fs2_lsf1 = QUOTE(
    SELECT file_name, file_timestamp
    FROM files_v2
    WHERE in_dir = :indir;
);

const char *sql_fs2_get1 = QUOTE(
    SELECT file_contents
    FROM files_v2
    WHERE in_dir = :indir AND file_name = :name;
);

const char *sql_fs2_put1 = QUOTE(
    INSERT INTO files_v2
    VALUES(:indir, :name, strftime('%s', 'now'), :contents);
);

const char *sql_fs2_ovr1 = QUOTE(
    UPDATE files_v2
    SET file_timestamp = strftime('%s', 'now'), file_contents = :contents
    WHERE in_dir = :indir AND file_name = :name;
);

const char *sql_fs2_del1 = QUOTE(
    DELETE FROM files_v2
    WHERE in_dir = :indir AND file_name = :name;
);

const char *sql_fs2_mvf1 = QUOTE(
    UPDATE files_v2
    SET in_dir = :to_dir, file_name = :to_name
    WHERE in_dir = :from_dir AND file_name = :from_name;
);
