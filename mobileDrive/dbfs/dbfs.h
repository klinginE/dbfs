#ifndef DBFS_H
#define DBFS_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>


typedef struct DBFS DBFS;
typedef enum DBFS_Error DBFS_Error;
typedef struct DBFS_Blob DBFS_Blob;
typedef struct DBFS_FileList DBFS_FileList;
typedef struct DBFS_FileName DBFS_FileName;
typedef struct DBFS_DirList DBFS_DirList;
typedef struct DBFS_DirName DBFS_DirName;


enum DBFS_Error
{
    DBFS_OKAY,
    DBFS_GENERAL_ERROR,
    DBFS_NO_SLASH,
};

// this structure is public; user should set them for dbfs_put
struct DBFS_Blob
{
    const uint8_t *data;
    size_t size;
};

struct DBFS_FileList
{
    const DBFS_FileName *files;
    size_t count;
};

struct DBFS_FileName
{
    const char *name;
};

struct DBFS_DirList
{
    const DBFS_DirName *dirs;
    size_t count;
};

struct DBFS_DirName
{
    const char *name;
};


DBFS *dbfs_open(const char *name);
void dbfs_close(DBFS *db);

DBFS_Error dbfs_get(DBFS *db, DBFS_FileName path, DBFS_Blob *out);
void dbfs_free_blob(DBFS_Blob blob);

DBFS_Error dbfs_put(DBFS *db, DBFS_FileName path, DBFS_Blob blob);
DBFS_Error dbfs_ovr(DBFS *db, DBFS_FileName path, DBFS_Blob blob);
DBFS_Error dbfs_del(DBFS *db, DBFS_FileName path);

DBFS_Error dbfs_lsf(DBFS *db, DBFS_DirName dir, DBFS_FileList *files);
void dbfs_free_file_list(DBFS_FileList fl);

DBFS_Error dbfs_lsd(DBFS *db, DBFS_DirName dir, DBFS_DirList *dirs);
void dbfs_free_dir_list(DBFS_DirList dl);

#endif //DBFS_H
