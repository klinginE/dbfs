#ifndef DBFS_H
#define DBFS_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>


typedef struct DBFS DBFS;
typedef enum DBFS_Error DBFS_Error;
typedef struct DBFS_Blob DBFS_Blob;


enum DBFS_Error
{
    DBFS_OKAY,
    DBFS_GENERAL_ERROR,
};

// this structure is public; user should set them for dbfs_put
struct DBFS_Blob
{
    const uint8_t *data;
    size_t size;
};


DBFS *dbfs_open(const char *name);
void dbfs_close(DBFS *db);

DBFS_Error dbfs_get(DBFS *db, const char *path, DBFS_Blob *out);
void dbfs_free_blob(DBFS_Blob blob);

DBFS_Error dbfs_put(DBFS *db, const char *path, DBFS_Blob blob);


#endif //DBFS_H
