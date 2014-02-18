#define QUOTE(str) #str

// Note: only single statements are currently supported by the DBFS code
// If you want to separate statements with semicolons, you'll need to:
// allocate an array of statements and loop the creation and destruction.

const char *sql_fs1_init = QUOTE(
    CREATE TABLE IF NOT EXISTS filesystem_v1
    (
        name TEXT,
        contents BLOB
    )
);

const char *sql_fs1_get = QUOTE(
    SELECT contents FROM filesystem_v1
    WHERE name == ?;
);

const char *sql_fs1_put = QUOTE(
    INSERT INTO filesystem_v1
    VALUES (?, ?);
);

const char *sql_fs1_del = QUOTE(
    DELETE FROM filesystem_v1
    WHERE name == ?;
);

const char *sql_fs1_lsf = QUOTE(
    SELECT name FROM filesystem_v1
    WHERE name LIKE (? || '%');
);
