#include "dbfs.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


static
DBFS_Blob slurp(FILE *in)
{
    uint8_t *buf = NULL;
    size_t size = 0, cap = 0;

    cap = 4096;
    buf = malloc(cap);
    while (true)
    {
        size_t got;
        if (size == cap)
        {
            cap *= 2;
            buf = realloc(buf, cap);
        }
        got = fread(buf + size, 1, cap - size, in);
        if (!got)
            break;
        size += got;
    }
    buf = realloc(buf, size);
    return (DBFS_Blob){buf, size};
}

static
int do_get(DBFS *dbfs, const char *fname, FILE *out)
{
    DBFS_Blob blob;
    if (!fname)
    {
        puts("missing argument");
        return 1;
    }
    if (DBFS_OKAY != dbfs_get(dbfs, (DBFS_FileName){fname}, &blob))
    {
        puts("not okay");
        return 2;
    }
    fwrite(blob.data, 1, blob.size, out);
    dbfs_free_blob(blob);
    return 0;
}

static
int do_put(DBFS *dbfs, const char *fname, FILE *in)
{
    DBFS_Blob blob;
    if (!fname)
    {
        puts("missing argument");
        return 1;
    }

    blob = slurp(in);
    if (DBFS_OKAY != dbfs_put(dbfs, (DBFS_FileName){fname}, blob))
    {
        puts("not okay");
        free((uint8_t *)blob.data);
        return 2;
    }
    return 0;
}

static
int do_del(DBFS *dbfs, const char *fname)
{
    if (!fname)
    {
        puts("missing argument");
        return 1;
    }

    if (DBFS_OKAY != dbfs_del(dbfs, (DBFS_FileName){fname}))
    {
        puts("not okay");
        return 2;
    }
    return 0;
}

static
int do_lsf(DBFS *dbfs, const char *fname, FILE *out)
{
    DBFS_FileList flist;
    size_t i;
    if (!fname)
    {
        puts("missing argument");
        return 1;
    }
    if (DBFS_OKAY != dbfs_lsf(dbfs, (DBFS_DirName){fname}, &flist))
    {
        puts("not okay");
        return 2;
    }
    fprintf(out, "%zu files:\n", flist.count);
    for (i = 0; i < flist.count; ++i)
        fprintf(out, "  [%zu]: %s\n", i, flist.files[i].name);
    dbfs_free_file_list(flist);
    return 0;
}

int main(int argc, char **argv)
{
    int rv = 0;
    const char *db_name;
    DBFS *dbfs_handle;

    if (argc < 2 || argv[1][0] == '-')
    {
        printf("Usage: %s {get|put} filename\n", argv[0]);
        return 0;
    }

    db_name = getenv("DBFS");
    if (db_name == NULL)
    {
        // in the App, this will be hard-coded
        puts("env DBFS unset, storing in memory (not persistent)");
        db_name = ":memory:";
    }
    dbfs_handle = dbfs_open(db_name);
    if (dbfs_handle == NULL)
    {
        puts("problem opening database");
    }

    if (strcmp(argv[1], "get") == 0)
    {
        rv = do_get(dbfs_handle, argv[2], stdout);
    }
    else if (strcmp(argv[1], "put") == 0)
    {
        rv = do_put(dbfs_handle, argv[2], stdin);
    }
    else if (strcmp(argv[1], "del") == 0)
    {
        rv = do_del(dbfs_handle, argv[2]);
    }
    else if (strcmp(argv[1], "lsf") == 0)
    {
        rv = do_lsf(dbfs_handle, argv[2], stdout);
    }
    else
    {
        printf("unknown command '%s'\n", argv[1]);
        rv = 1;
    }

    dbfs_close(dbfs_handle);
    return rv;
}
