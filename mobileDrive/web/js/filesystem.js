var files = [
  {
    "name": "root",
    "type": "root",
    "icon": "directory",
    "contents": [
      {
        "name": "Folder 1",
        "size": '',
        "modified": "2014-03-01 13:31",
        "type": "Directory",
        "icon": "directory",
        "contents": [
          {
            "name": "SuperSub",
            "size": '',
            'modofied': "2014-03-01 13:35",
            "type": 'Directory',
            "icon": 'directory',
            'contents': [
              {
                "name": "f1.txt",
                "size": 4325,
                "modified": "2014-03-01 13:31",
                "type": "Text File",
                "icon": "text"
              },
              {
                "name": "f2.txt",
                "size": 321,
                "modified": "2014-03-01 13:31",
                "type": "Text File",
                "icon": "text"
              },
              {
                "name": "F3.txt",
                "size": 76578,
                "modified": "2014-03-01 13:31",
                "type": "Text File",
                "icon": "text"
              }
            ]
          },
          {
            "name": "file1.txt",
            "size": 67870,
            "modified": "2014-03-01 13:31",
            "type": "Text File",
            "icon": "text"
          },
          {
            "name": "file2.txt",
            "size": 563654,
            "modified": "2014-03-01 13:31",
            "type": "Text File",
            "icon": "text"
          },
          {
            "name": "file3.txt",
            "size": 5695679,
            "modified": "2014-03-01 13:31",
            "type": "Text File",
            "icon": "text"
          }
        ]
      },
      {
        "name": "Folder 2",
        "size": '',
        "modified": "2014-03-05 13:32",
        "type": "Directory",
        "icon": "directory",
        "contents": [
          {
            "name": "aaa.txt",
            "size": 236623,
            "modified": "2014-03-01 13:31",
            "type": "Text File",
            "icon": "text"
          },
          {
            "name": "bbb.txt",
            "size": 146,
            "modified": "2014-03-01 13:31",
            "type": "Text File",
            "icon": "text"
          },
          {
            "name": "ccc.txt",
            "size": 64366,
            "modified": "2014-03-01 13:31",
            "type": "Text File",
            "icon": "text"
          }
        ]
      },
      {
        "name": "Folder 3",
        "size": '',
        "modified": "2014-02-28 19:11",
        "type": "Directory",
        "icon": "directory",
        "contents": [
          {
            "name": "zed.txt",
            "size": 124532,
            "modified": "2014-03-01 13:31",
            "type": "Text File",
            "icon": "text"
          }
        ]
      },
      {
        "name": "bar.txt",
        "size": 8568,
        "modified": "2014-03-01 13:34",
        "type": "Text File",
        "icon": "text"
      },
      {
        "name": "bla.txt",
        "size": 1024,
        "modified": "2014-03-01 13:37",
        "type": "Text File",
        "icon": "text"
      },
      {
        "name": "foo.txt",
        "size": 432,
        "modified": "2014-03-01 13:39",
        "type": "Text File",
        "icon": "text"
      },
      {
        "name": "AnotherText.txt",
        "size": 521,
        "modified": "2014-03-01 13:30",
        "type": "Text File",
        "icon": "text"
      },
      {
        "name": "SomeText.txt",
        "size": 12048,
        "modified": "2014-03-01 13:39",
        "type": "Text File",
        "icon": "text"
      }
    ]
  }
];

var path = ["root"];
var cwd = files[0].contents;
var sort = 'sort-type';
var sortFunc = null;
var sortReverse = false;