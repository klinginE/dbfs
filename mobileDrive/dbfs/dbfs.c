#include "dbfs.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <sqlite3.h>

#include "dbfs__literals.h"

struct DBFS
{
    sqlite3 *db;
    sqlite3_stmt *indir;
    sqlite3_stmt *mkd1;
    sqlite3_stmt *rmd1;
    sqlite3_stmt *mvd1;
    sqlite3_stmt *lsd1;
    sqlite3_stmt *lsf1;
    sqlite3_stmt *get1;
    sqlite3_stmt *put1;
    sqlite3_stmt *ovr1;
    sqlite3_stmt *del1;
    sqlite3_stmt *mvf1;
};


static __attribute__((noreturn))
void dbfs_fatal(const char *msg)
{
    fprintf(stderr, "%s\n", msg);
    abort();
}

static __attribute__((noreturn))
void sql_fatal(sqlite3 *db, int err)
{
    if (err == SQLITE_OK)
        dbfs_fatal("nothing is wrong");
    if (err == SQLITE_MISUSE)
        dbfs_fatal("sqlite misuse!");
    #if SQLITE_VERSION_NUMBER >= 3007015
    fprintf(stderr, "error %d\n: %s\n", err, sqlite3_errstr(err));
    #else
    fprintf(stderr, "error %d\n", err);
    #endif
    fprintf(stderr, "message: %s\n", sqlite3_errmsg(db));
    abort();
}

static
void sql_check(sqlite3 *db, int err)
{
    if (err == SQLITE_OK)
        return;
    sql_fatal(db, err);
}

static
DBFS_Error sql_map(int err)
{
    switch (err)
    {
    case SQLITE_MISUSE:
        dbfs_fatal("misuse!");
    case SQLITE_CONSTRAINT:
        return DBFS_INTRUDER;
    default:
        return DBFS_YOU_SUCK;
    }
}


static
sqlite3_stmt *compile_statement(sqlite3 *db, const char *stmt)
{
    sqlite3_stmt *rv;
    const char *rest;

    int err = sqlite3_prepare_v2(db, stmt, strlen(stmt) + 1, &rv, &rest);
    sql_check(db, err);
    if (*rest)
        dbfs_fatal("failed to consume input");
    return rv;
}

static
void free_statement(sqlite3 *db, sqlite3_stmt *s)
{
    int err = sqlite3_finalize(s);
    sql_check(db, err);
}

static
void print_escaped(const char *text)
{
    printf("%s", text);
}

static
void print_blob(const uint8_t *blob, size_t size)
{
    fwrite(blob, 1, size, stdout);
}

static
void debug_result(sqlite3_stmt *query)
{
    int type, i, count;
    if (!getenv("DBFS_DEBUG"))
    {
        return;
    }

    count = sqlite3_column_count(query);
    if (count == 0)
    {
        printf("no results\n\n");
        return;
    }
    for (i = 0; i < count; ++i)
    {
        printf("name: %s\n", sqlite3_column_name(query, i));
        type = sqlite3_column_type(query, i);
        switch (type)
        {
        case SQLITE_INTEGER:
            printf("int: %d\n", sqlite3_column_int(query, i));
            break;
        case SQLITE_FLOAT:
            printf("float: %f\n", sqlite3_column_double(query, i));
            break;
        case SQLITE_TEXT:
            {
                const unsigned char *text = sqlite3_column_text(query, i);
                printf("text: ");
                print_escaped((const char *)text);
                printf("\n");
            }
            break;
        case SQLITE_BLOB:
            {
                const void *blob = sqlite3_column_text(query, i);
                size_t size = sqlite3_column_bytes(query, i);
                printf("blob: ");
                print_blob((const uint8_t *)blob, size);
                printf("\n");
            }
            break;
        case SQLITE_NULL:
            printf("null: NULL\n");
            break;
        default:
            dbfs_fatal("unknown sql data type");
        }
        printf("\n");
    }
}

static
void *memdup(const void *mem, size_t sz)
{
    void *rv = malloc(sz);
    memcpy(rv, mem, sz);
    return rv;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"

#define BIND_INDEX(name) ({ int idx = sqlite3_bind_parameter_index(query, ":" #name); if (!idx) dbfs_fatal("Unbound: " #name); idx; })

#define BIND_INT(name) do { int err = sqlite3_bind_int(query, BIND_INDEX(name), name); sql_check(db->db, err); } while (0)
#define BIND_TEXT(name, size) do { int err = sqlite3_bind_text(query, BIND_INDEX(name), name, size, SQLITE_TRANSIENT); sql_check(db->db, err); } while (0)
#define BIND_BLOB(name, size) do { int err = sqlite3_bind_blob(query, BIND_INDEX(name), name, size, SQLITE_TRANSIENT); sql_check(db->db, err); } while (0)

DBFS_Error query_id1(DBFS *db, int *in_dir, const char *name, size_t name_len)
{
    sqlite3_stmt *query = db->indir;
    int indir = *in_dir;
    BIND_INT(indir);
    BIND_TEXT(name, name_len);
    int count = 0;
    DBFS_Error rv = DBFS_OKAY;
    while (true)
    {
        int status = sqlite3_step(query);
        if (status == SQLITE_ROW)
        {
            debug_result(query);
            if (count)
                dbfs_fatal("too many results");
            count++;
            *in_dir = sqlite3_column_int(query, 0);
            continue;
        }
        sqlite3_reset(query);
        if (status != SQLITE_DONE)
            rv = sql_map(status);
        break;
    }
    sqlite3_clear_bindings(query);
    if (!count)
        return DBFS_LIGHTS_ON;
    return rv;
}

DBFS_Error query_mkd1(DBFS *db, int indir, const char *name)
{
    sqlite3_stmt *query = db->mkd1;
    BIND_INT(indir);
    BIND_TEXT(name, -1);
    DBFS_Error rv = DBFS_OKAY;
    while (true)
    {
        int status = sqlite3_step(query);
        if (status == SQLITE_ROW)
        {
            debug_result(query);
            dbfs_fatal("didn't expect any results");
            continue;
        }
        sqlite3_reset(query);
        if (status != SQLITE_DONE)
            rv = sql_map(status);
        break;
    }
    sqlite3_clear_bindings(query);
    return rv;
}

DBFS_Error query_rmd1(DBFS *db, int indir, const char *name)
{
    sqlite3_stmt *query = db->rmd1;
    BIND_INT(indir);
    BIND_TEXT(name, -1);
    DBFS_Error rv = DBFS_OKAY;
    while (true)
    {
        int status = sqlite3_step(query);
        if (status == SQLITE_ROW)
        {
            debug_result(query);
            dbfs_fatal("didn't expect any results");
            continue;
        }
        sqlite3_reset(query);
        if (status != SQLITE_DONE)
            rv = sql_map(status);
        break;
    }
    sqlite3_clear_bindings(query);
    return rv;
}

DBFS_Error query_mvd1(DBFS *db, int from_dir, const char *from_name, int to_dir, const char *to_name)
{
    sqlite3_stmt *query = db->mvd1;
    BIND_INT(from_dir);
    BIND_TEXT(from_name, -1);
    BIND_INT(to_dir);
    BIND_TEXT(to_name, -1);
    DBFS_Error rv = DBFS_OKAY;
    while (true)
    {
        int status = sqlite3_step(query);
        if (status == SQLITE_ROW)
        {
            debug_result(query);
            dbfs_fatal("didn't expect any results");
            continue;
        }
        sqlite3_reset(query);
        if (status != SQLITE_DONE)
            rv = sql_map(status);
        break;
    }
    sqlite3_clear_bindings(query);
    return rv;
}

DBFS_Error query_lsd1(DBFS *db, int indir, DBFS_DirName **out_dirs, size_t *out_size)
{
    sqlite3_stmt *query = db->lsd1;
    BIND_INT(indir);
    size_t out_cap = 16;
    *out_dirs = malloc(out_cap * sizeof(**out_dirs));
    *out_size = 0;
    DBFS_Error rv = DBFS_OKAY;
    while (true)
    {
        int status = sqlite3_step(query);
        if (status == SQLITE_ROW)
        {
            debug_result(query);
            const char *text = strdup((const char *)sqlite3_column_text(query, 0));
            if (out_cap == *out_size)
            {
                out_cap *= 2;
                *out_dirs = realloc(*out_dirs, out_cap * sizeof(**out_dirs));
            }
            (*out_dirs)[(*out_size)++] = (DBFS_DirName){text};
            continue;
        }
        sqlite3_reset(query);
        if (status != SQLITE_DONE)
            rv = sql_map(status);
        break;
    }
    sqlite3_clear_bindings(query);
    return rv;
}

DBFS_Error query_lsf1(DBFS *db, int indir, DBFS_FileName **out_files, size_t *out_size)
{
    sqlite3_stmt *query = db->lsf1;
    BIND_INT(indir);
    size_t out_cap = 16;
    *out_files = malloc(out_cap * sizeof(**out_files));
    *out_size = 0;
    DBFS_Error rv = DBFS_OKAY;
    while (true)
    {
        int status = sqlite3_step(query);
        if (status == SQLITE_ROW)
        {
            debug_result(query);
            const char *text = (const char *)(sqlite3_column_text(query, 0));
            text = strdup(text);
            int timestamp = sqlite3_column_int(query, 1);
            int filesize = sqlite3_column_int(query, 2);
            if (out_cap == *out_size)
            {
                out_cap *= 2;
                *out_files = realloc(*out_files, out_cap * sizeof(**out_files));
            }
            (*out_files)[(*out_size)++] = (DBFS_FileName){text, timestamp, filesize};
            continue;
        }
        sqlite3_reset(query);
        if (status != SQLITE_DONE)
            rv = sql_map(status);
        break;
    }
    sqlite3_clear_bindings(query);
    return rv;
}

DBFS_Error query_get1(DBFS *db, int indir, const char *name, uint8_t **out_body, size_t *out_size)
{
    sqlite3_stmt *query = db->get1;
    BIND_INT(indir);
    BIND_TEXT(name, -1);
    int count = 0;
    DBFS_Error rv = DBFS_OKAY;
    while (true)
    {
        int status = sqlite3_step(query);
        if (status == SQLITE_ROW)
        {
            debug_result(query);
            if (count)
                dbfs_fatal("too many results");
            count++;
            const uint8_t *blob = sqlite3_column_blob(query, 0);
            *out_size = sqlite3_column_bytes(query, 0);
            *out_body = memdup(blob, *out_size);
            continue;
        }
        sqlite3_reset(query);
        if (status != SQLITE_DONE)
            rv = sql_map(status);
        break;
    }
    sqlite3_clear_bindings(query);
    if (!count)
        return DBFS_LIGHTS_ON;
    return rv;
}

DBFS_Error query_put1(DBFS *db, int indir, const char *name, const uint8_t *contents, size_t size)
{
    sqlite3_stmt *query = db->put1;
    BIND_INT(indir);
    BIND_TEXT(name, -1);
    BIND_BLOB(contents, size);
    DBFS_Error rv = DBFS_OKAY;
    while (true)
    {
        int status = sqlite3_step(query);
        if (status == SQLITE_ROW)
        {
            debug_result(query);
            dbfs_fatal("didn't expect any results");
            continue;
        }
        sqlite3_reset(query);
        if (status != SQLITE_DONE)
            rv = sql_map(status);
        break;
    }
    sqlite3_clear_bindings(query);
    return rv;
}

DBFS_Error query_ovr1(DBFS *db, int indir, const char *name, const uint8_t *contents, size_t size)
{
    sqlite3_stmt *query = db->ovr1;
    BIND_INT(indir);
    BIND_TEXT(name, -1);
    BIND_BLOB(contents, size);
    DBFS_Error rv = DBFS_OKAY;
    while (true)
    {
        int status = sqlite3_step(query);
        if (status == SQLITE_ROW)
        {
            debug_result(query);
            dbfs_fatal("didn't expect any results");
            continue;
        }
        sqlite3_reset(query);
        if (status != SQLITE_DONE)
            rv = sql_map(status);
        break;
    }
    sqlite3_clear_bindings(query);
    return rv;
}

DBFS_Error query_del1(DBFS *db, int indir, const char *name)
{
    sqlite3_stmt *query = db->del1;
    BIND_INT(indir);
    BIND_TEXT(name, -1);
    DBFS_Error rv = DBFS_OKAY;
    while (true)
    {
        int status = sqlite3_step(query);
        if (status == SQLITE_ROW)
        {
            debug_result(query);
            dbfs_fatal("didn't expect any results");
            continue;
        }
        sqlite3_reset(query);
        if (status != SQLITE_DONE)
            rv = sql_map(status);
        break;
    }
    sqlite3_clear_bindings(query);
    return rv;
}

DBFS_Error query_mvf1(DBFS *db, int from_dir, const char *from_name, int to_dir, const char *to_name)
{
    sqlite3_stmt *query = db->mvf1;
    BIND_INT(from_dir);
    BIND_TEXT(from_name, -1);
    BIND_INT(to_dir);
    BIND_TEXT(to_name, -1);
    DBFS_Error rv = DBFS_OKAY;
    while (true)
    {
        int status = sqlite3_step(query);
        if (status == SQLITE_ROW)
        {
            debug_result(query);
            dbfs_fatal("didn't expect any results");
            continue;
        }
        sqlite3_reset(query);
        if (status != SQLITE_DONE)
            rv = sql_map(status);
        break;
    }
    sqlite3_clear_bindings(query);
    return rv;
}

#pragma GCC diagnostic pop


DBFS *dbfs_open(const char *name)
{
    DBFS *rv;
    sqlite3 *db = NULL;

    int err;
    err = sqlite3_open(name, &db);
    sql_check(db, err);
    err = sqlite3_exec(db, sql_fs2_init, NULL, NULL, NULL);
    sql_check(db, err);

    rv = malloc(sizeof(DBFS));
    rv->db = db;
    rv->indir = compile_statement(db, sql_fs2_indir);
    rv->mkd1 = compile_statement(db, sql_fs2_mkd1);
    rv->rmd1 = compile_statement(db, sql_fs2_rmd1);
    rv->mvd1 = compile_statement(db, sql_fs2_mvd1);
    rv->lsd1 = compile_statement(db, sql_fs2_lsd1);
    rv->lsf1 = compile_statement(db, sql_fs2_lsf1);
    rv->get1 = compile_statement(db, sql_fs2_get1);
    rv->put1 = compile_statement(db, sql_fs2_put1);
    rv->ovr1 = compile_statement(db, sql_fs2_ovr1);
    rv->del1 = compile_statement(db, sql_fs2_del1);
    rv->mvf1 = compile_statement(db, sql_fs2_mvf1);
    return rv;
}

void dbfs_close(DBFS *dbfs)
{
    free_statement(dbfs->db, dbfs->indir);
    free_statement(dbfs->db, dbfs->mkd1);
    free_statement(dbfs->db, dbfs->rmd1);
    free_statement(dbfs->db, dbfs->mvd1);
    free_statement(dbfs->db, dbfs->lsd1);
    free_statement(dbfs->db, dbfs->lsf1);
    free_statement(dbfs->db, dbfs->get1);
    free_statement(dbfs->db, dbfs->put1);
    free_statement(dbfs->db, dbfs->ovr1);
    free_statement(dbfs->db, dbfs->del1);
    free_statement(dbfs->db, dbfs->mvf1);
    int err = sqlite3_close(dbfs->db);
    sql_check(dbfs->db, err);
    free(dbfs);
}


DBFS_Error lookup_dir(DBFS *db, int *in_dir, DBFS_DirName *dir)
{
    if (dir->name[0] != '/')
        return DBFS_NOT_ABSOLUTE;
    if (dir->name[strlen(dir->name)-1] != '/')
        return DBFS_NOT_DIRNAME;
    ++dir->name;
    *in_dir = 0;
    while (true)
    {
        const char *slash = strchr(dir->name, '/');
        if (!slash[1])
            return DBFS_OKAY;
        ++slash;
        DBFS_Error err = query_id1(db, in_dir, dir->name, slash - dir->name);
        if (err)
            return err;
        dir->name = slash;
    }
}

DBFS_Error lookup_dir_harder(DBFS *db, int *in_dir, DBFS_DirName dir)
{
    if (strcmp(dir.name, "/") == 0)
    {
        *in_dir = 0;
        return DBFS_OKAY;
    }
    DBFS_Error err;
    err = lookup_dir(db, in_dir, &dir);
    if (!err)
        err = query_id1(db, in_dir, dir.name, strlen(dir.name));
    return err;
}

DBFS_Error lookup_file(DBFS *db, int *in_dir, DBFS_FileName *file)
{
    if (file->name[0] != '/')
        return DBFS_NOT_ABSOLUTE;
    if (file->name[strlen(file->name)-1] == '/')
        return DBFS_NOT_FILENAME;
    ++file->name;
    *in_dir = 0;
    while (true)
    {
        const char *slash = strchr(file->name, '/');
        if (!slash)
            return DBFS_OKAY;
        ++slash;
        DBFS_Error err = query_id1(db, in_dir, file->name, slash - file->name);
        if (err)
            return err;
        file->name = slash;
    }
}


DBFS_Error dbfs_mkd(DBFS *db, DBFS_DirName name)
{
    DBFS_Error err;
    int id;
    err = lookup_dir(db, &id, &name);
    if (err) return err;
    err = query_mkd1(db, id, name.name);
    return err;
}

DBFS_Error dbfs_rmd(DBFS *db, DBFS_DirName name)
{
    DBFS_Error err;
    int id;
    err = lookup_dir(db, &id, &name);
    if (err) return err;
    err = query_rmd1(db, id, name.name);
    return err;
}

DBFS_Error dbfs_mvd(DBFS *db, DBFS_DirName old_name, DBFS_DirName new_name)
{
    DBFS_Error err;
    int old_id, new_id;
    err = lookup_dir(db, &old_id, &old_name);
    if (err) return err;
    err = lookup_dir(db, &new_id, &new_name);
    if (err) return err;
    err = query_mvd1(db, old_id, old_name.name, new_id, new_name.name);
    return err;
}

DBFS_Error dbfs_lsd(DBFS *db, DBFS_DirName name, DBFS_DirList *dirs)
{
    DBFS_Error err;
    int id;
    DBFS_DirName *out_dirs = NULL;
    err = lookup_dir_harder(db, &id, name);
    if (err) return err;
    err = query_lsd1(db, id, &out_dirs, &dirs->count);
    dirs->dirs = out_dirs;
    return err;
}

DBFS_Error dbfs_lsf(DBFS *db, DBFS_DirName name, DBFS_FileList *files)
{
    DBFS_Error err;
    int id;
    DBFS_FileName *out_files = NULL;
    err = lookup_dir_harder(db, &id, name);
    if (err) return err;
    err = query_lsf1(db, id, &out_files, &files->count);
    files->files = out_files;
    return err;
}

DBFS_Error dbfs_get(DBFS *db, DBFS_FileName name, DBFS_Blob *out)
{
    DBFS_Error err;
    int id;
    uint8_t *out_bytes = NULL;
    err = lookup_file(db, &id, &name);
    if (err) return err;
    err = query_get1(db, id, name.name, &out_bytes, &out->size);
    out->data = out_bytes;
    return err;
}

DBFS_Error dbfs_put(DBFS *db, DBFS_FileName name, DBFS_Blob in)
{
    DBFS_Error err;
    int id;
    err = lookup_file(db, &id, &name);
    if (err) return err;
    err = query_put1(db, id, name.name, in.data, in.size);
    return err;
}

DBFS_Error dbfs_ovr(DBFS *db, DBFS_FileName name, DBFS_Blob in)
{
    DBFS_Error err;
    int id;
    err = lookup_file(db, &id, &name);
    if (err) return err;
    err = query_ovr1(db, id, name.name, in.data, in.size);
    return err;
}

DBFS_Error dbfs_del(DBFS *db, DBFS_FileName name)
{
    DBFS_Error err;
    int id;
    err = lookup_file(db, &id, &name);
    if (err) return err;
    err = query_del1(db, id, name.name);
    return err;
}

DBFS_Error dbfs_mvf(DBFS *db, DBFS_FileName old_name, DBFS_FileName new_name)
{
    DBFS_Error err;
    int old_id, new_id;
    err = lookup_file(db, &old_id, &old_name);
    if (err) return err;
    err = lookup_file(db, &new_id, &new_name);
    if (err) return err;
    err = query_mvf1(db, old_id, old_name.name, new_id, new_name.name);
    return err;
}


void dbfs_free_blob(DBFS_Blob blob)
{
    // cast away const
    free((uint8_t *)blob.data);
}

void dbfs_free_dir_list(DBFS_DirList dl)
{
    while (dl.count--)
    {
        free((char *)dl.dirs[dl.count].name);
    }
    free((DBFS_DirName *)dl.dirs);
}

void dbfs_free_file_list(DBFS_FileList fl)
{
    while (fl.count--)
    {
        free((char *)fl.files[fl.count].name);
    }
    free((DBFS_FileName *)fl.files);
}


const char *dbfs_err(DBFS_Error err)
{
    switch (err)
    {
        case DBFS_OKAY:
            return "Everything is Ok.";
        case DBFS_NOT_ABSOLUTE:
            return "Argument was not absolute.";
        case DBFS_NOT_DIRNAME:
            return "Argument was not a valid directory name.";
        case DBFS_NOT_FILENAME:
            return "Argument was not a valid file name.";
        case DBFS_COMPONENT_TOO_LONG:
            return "A pathname component was too long.";
        case DBFS_LIGHTS_ON:
            return "File/Directory does not exists";
        case DBFS_INTRUDER:
            return "File/Directory already exists";
        case DBFS_YOU_SUCK:
            return "The database doesn't like you. I don't like you either.";
        default:
            dbfs_fatal("unknown error");
    }
}
