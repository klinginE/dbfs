#include "dbfs.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <sqlite3.h>

#include "dbfs__literals.h"

struct DBFS
{
    sqlite3 *db;
    sqlite3_stmt *get;
    sqlite3_stmt *put;
};


static
void dbfs_fatal()
{
    abort();
}


static
sqlite3_stmt *compile_statement(sqlite3 *db, const char *stmt)
{
    sqlite3_stmt *rv;
    const char *rest;

    if (SQLITE_OK != sqlite3_prepare_v2(db, stmt, strlen(stmt) + 1, &rv, &rest))
        dbfs_fatal();
    if (*rest)
        dbfs_fatal();
    return rv;
}

static
void free_statement(sqlite3_stmt *s)
{
    if (SQLITE_OK != sqlite3_finalize(s))
        dbfs_fatal();
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
            dbfs_fatal();
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


static
void run_query_init(sqlite3_stmt *query)
{
    while (true)
    {
        int status = sqlite3_step(query);
        if (status == SQLITE_ROW)
        {
            debug_result(query);
            dbfs_fatal();
            continue;
        }
        sqlite3_reset(query);
        if (status == SQLITE_DONE)
            break;
        dbfs_fatal();
    }
    sqlite3_clear_bindings(query);
}

static
DBFS_Error run_query_get(sqlite3_stmt *query, const char *name, uint8_t **out_body, size_t *out_size)
{
    // bindings are 1-based but result columns are 0-based. Wtf?
    int count = 0;
    sqlite3_bind_text(query, 1, name, strlen(name), SQLITE_TRANSIENT);
    while (true)
    {
        int status = sqlite3_step(query);
        if (status == SQLITE_ROW)
        {
            const void *blob;
            size_t size;
            debug_result(query);
            if (count)
                dbfs_fatal();
            blob = sqlite3_column_blob(query, 0);
            size = sqlite3_column_bytes(query, 0);
            *out_body = memdup(blob, size);
            *out_size = size;
            count++;
            continue;
        }
        sqlite3_reset(query);
        if (status == SQLITE_DONE)
            break;
        dbfs_fatal();
    }
    sqlite3_clear_bindings(query);
    if (count == 0)
    {
        *out_body = NULL;
        *out_size = 0;
        return DBFS_GENERAL_ERROR;
    }
    return DBFS_OKAY;
}

static
DBFS_Error run_query_put(sqlite3_stmt *query, const char *name, const uint8_t *body, size_t size)
{
    sqlite3_bind_text(query, 1, name, strlen(name), SQLITE_TRANSIENT);
    sqlite3_bind_blob(query, 2, body, size, SQLITE_TRANSIENT);
    while (true)
    {
        int status = sqlite3_step(query);
        if (status == SQLITE_ROW)
        {
            debug_result(query);
            abort();
            continue;
        }
        sqlite3_reset(query);
        if (status == SQLITE_DONE)
            break;
        dbfs_fatal();
    }
    sqlite3_clear_bindings(query);
    return DBFS_OKAY;
}


DBFS *dbfs_open(const char *name)
{
    DBFS *rv;
    sqlite3 *db;

    if (SQLITE_OK != sqlite3_open(name, &db))
        return NULL;
    sqlite3_stmt *init = compile_statement(db, sql_fs1_init);
    run_query_init(init);
    free_statement(init);

    rv = malloc(sizeof(DBFS));
    rv->db = db;
    rv->get = compile_statement(db, sql_fs1_get);
    rv->put = compile_statement(db, sql_fs1_put);
    return rv;
}

void dbfs_close(DBFS *dbfs)
{
    free_statement(dbfs->get);
    free_statement(dbfs->put);
    if (SQLITE_OK != sqlite3_close(dbfs->db))
        dbfs_fatal();
    free(dbfs);
}

DBFS_Error dbfs_get(DBFS *dbfs, const char *path, DBFS_Blob *out)
{
    uint8_t *data = NULL;
    size_t size = 0;
    DBFS_Error err;
    err = run_query_get(dbfs->get, path, &data, &size);
    out->data = data;
    out->size = size;
    return err;
}

void dbfs_free_blob(DBFS_Blob blob)
{
    // cast away const
    free((uint8_t *)blob.data);
}

DBFS_Error dbfs_put(DBFS *dbfs, const char *path, DBFS_Blob blob)
{
    DBFS_Error err;
    err = run_query_put(dbfs->put, path, blob.data, blob.size);
    return err;
}
