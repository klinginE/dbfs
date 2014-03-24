#define QUOTE(str) #str

// Note: only single statements are currently supported by the DBFS code
// If you want to separate statements with semicolons, you'll need to:
// allocate an array of statements and loop the creation and destruction.

const char *sql_fs1_init = QUOTE(
    CREATE TABLE IF NOT EXISTS filesystem_v1
    (
        name TEXT PRIMARY KEY,
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

const char *sql_fs1_ovr = QUOTE(
    UPDATE filesystem_v1
    SET contents = ?
    WHERE name = ?;
);

const char *sql_fs1_del = QUOTE(
    DELETE FROM filesystem_v1
    WHERE name == ?;
);

// grumble, more 1-based indexing
const char *sql_fs1_lsf = QUOTE(
    SELECT substr(name, length(?1) + 1) FROM filesystem_v1
    WHERE instr(name, ?1) == 1 and instr(substr(name, length(?1) + 1), '/') == 0;
);

const char *sql_fs1_lsd = QUOTE(
    SELECT DISTINCT substr(name, length(?1) + 1, instr(substr(name, length(?1) + 1), '/')) FROM filesystem_v1
    WHERE instr(name, ?1) == 1 and instr(substr(name, length(?1) + 1), '/') != 0;
);

const char *sql_fs1_mvf = QUOTE(
    UPDATE filesystem_v1
    SET name = ?2
    WHERE name = ?1;
);

const char *sql_fs1_mvd = QUOTE(
    UPDATE filesystem_v1
    SET name = ?2 || substr(name, length(?1) + 1)
    WHERE instr(name, ?1) == 1;
);
