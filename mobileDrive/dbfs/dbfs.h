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
    // Everything is Ok.
    DBFS_OKAY,

    // Argument was not absolute.
    DBFS_NOT_ABSOLUTE,
    // Argument was not a valid directory name.
    DBFS_NOT_DIRNAME,
    // Argument was not a valid file name.
    DBFS_NOT_FILENAME,
    // A pathname component was too long.
    DBFS_COMPONENT_TOO_LONG,

    // Nobody's home.
    DBFS_LIGHTS_ON,
    // Somebody's home.
    DBFS_INTRUDER,
    // The database doesn't like you. I don't like you either.
    DBFS_YOU_SUCK,

    // Note that internal errors call abort() instead of returning
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
    int timestamp;
    int size;
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

DBFS_Error dbfs_mkd(DBFS *db, DBFS_DirName name);
DBFS_Error dbfs_rmd(DBFS *db, DBFS_DirName name); // recursive only
DBFS_Error dbfs_mvd(DBFS *db, DBFS_DirName old_name, DBFS_DirName new_name);
DBFS_Error dbfs_lsd(DBFS *db, DBFS_DirName name, DBFS_DirList *dirs);
DBFS_Error dbfs_lsf(DBFS *db, DBFS_DirName name, DBFS_FileList *files);
DBFS_Error dbfs_get(DBFS *db, DBFS_FileName name, DBFS_Blob *out);
DBFS_Error dbfs_put(DBFS *db, DBFS_FileName name, DBFS_Blob in);
DBFS_Error dbfs_ovr(DBFS *db, DBFS_FileName name, DBFS_Blob in);
DBFS_Error dbfs_del(DBFS *db, DBFS_FileName name);
DBFS_Error dbfs_mvf(DBFS *db, DBFS_FileName old_name, DBFS_FileName new_name);

// free the result of get
void dbfs_free_blob(DBFS_Blob blob);
// free the result of lsd
void dbfs_free_dir_list(DBFS_DirList dl);
// free the result of lsf
void dbfs_free_file_list(DBFS_FileList fl);

const char *dbfs_err(DBFS_Error err);

#endif //DBFS_H
