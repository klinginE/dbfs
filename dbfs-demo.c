#include "dbfs.h"

#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
    const char *db_name;
    DBFS *dbfs_handle;

    if (argc < 2 || argc > 2 || argv[1][0] == '-')
    {
        printf("Usage: %s {get|put}\n", argv[0]);
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

    printf("Would %s in %s\n", argv[1], db_name);
    // insert main logic here

    dbfs_close(dbfs_handle);
    return 0;
}
