$(function() {
  var path = ["/"];
  var cwd = [];
  var cwdHash = "";
  var sort = 'sort-type';
  var sortFunc = compareType;
  var sortReverse = false;
  var modal = null;
  
  // Load the file list
  getDir();

  // Select item from file list
  $('#file-list').click(function(e) {
      $('#file-list tr td').removeClass('selected');
      var row = $(e.target).closest('tr');

      if (row.attr('id') == 'header-row') {
        $('#actions #file-actions .button').addClass('disable');
      } else {
        row.children('td').addClass('selected');
        $('#actions #file-actions .button').removeClass('disable');
        
        // Changing open button label to "Download" or "Open" depending on its type.
        var fileType = $('td.selected.file-type').text().trim();
        if (fileType === "File") {
            $('#open-button').text("Download");
        } else {
            $('#open-button').text("Open");
        }
      }
  });

  // Sort by...
  $('#header-row').click(function(e) {
    var header = $(e.target).closest('th');
    var id = header.attr('id');

    $('#header-row th img').remove();

    if (id === sort) {
      sortReverse = !sortReverse;
    } else {
      sort = id;
      sortReverse = false;
    }

    var sf = null;

    if (sort === 'sort-name') {
      sf = compareName;
    } else if (sort === 'sort-date') {
      sf = compareDate;
    } else if (sort === 'sort-type') {
      sf = compareType;
    } else if (sort === 'sort-size') {
      sf = compareSize;
    }

    if (sortReverse) {
      sortFunc = function(a, b) { return -(sf(a, b)); }
      header.prepend('<img src="img/arrow_up.png"> ');
    } else {
      sortFunc = sf;
      header.prepend('<img src="img/arrow_down.png"> ');
    }

    rebuildFileList();
  });

  // Open item from file list
  $('#file-list').dblclick(function(e) {
    var row = $(e.target).closest('tr');
    var file = row.find("td:first-child").text().trim();
    if (row.hasClass("directory")) {
      openDir(file);
    }
  });

  // Breadcrumb links
  $('#breadcrumbs').click(function(e) {
    if (!$(e.target).is('a')) {
      return;
    }

    var link = $(e.target);
    var id = link.attr('id');
    id = parseInt(id.substr(2, id.length));
    path = path.splice(0, id+1);

    getDir();

    rebuildFileList();
    rebuildBreadCrumbs();
  });

  // Select file to upload
  $('#select-file-button').click(function() {
    $('#upload-file').click();
  });

  // File was selected to upload
  $('#upload-file').change(function(){
    var path = $(this).val();
    if (path.match(/fakepath/)) {
      path = path.replace(/C:\\fakepath\\/i, '');
    }
    $('#select-file-button').text(path);
    $('#upload-button').removeClass('disable');
  });
  
  // Upload file button
  $('#upload-button').click(function() {
    if ($('#upload-button').hasClass('disable')) return;
    $('#upload-progress > div').css('width', '0');
    $('#upload-progress > div').text('');
    
    var dirPath = "/";
    for (var i = 1; i < path.length; i++) {
      dirPath += path[i] + "/";
    }
    
    var formData = new FormData($('#upload-form')[0]);
    formData.append('upload-dir', dirPath);
    $.ajax({
      url: 'upload.html',
      type: 'POST',
      xhr: function() {
        var myXhr = $.ajaxSettings.xhr();
        if (myXhr.upload) {
          myXhr.upload.addEventListener('progress', uploadProgress, false);
        }
        return myXhr; 
      },
      success: function(data, textStatus, hqXHR) {
        getDir();
        $('#select-file-button').text("Select file...");
        $('#upload-button').addClass('disable');
        $('#upload-progress > div').text('Done!');
        setTimeout(clearProgressBar, 3000);
      },
      data: formData,
      cache: false,
      contentType: false,
      processData: false
    });
    
    $('#upload-form').each(function(){
      this.reset();
    });
  });
  
  // Delete button
  $('#delete-button').click(function() {
    if ($('#delete-button').hasClass('disable')) return;
    
    var fileName = $('td.selected.file-name').text().trim();
    var fileType = $('td.selected.file-type').text().trim();
    
    if (fileName === "") {
      return;
    }
                            
    var checkstr =  confirm("Are you sure you want to delete "+ fileName +"?");
    if (checkstr == true) {
        var filePath = "/";
        for (var i = 1; i < path.length; i++) {
          filePath += path[i] + "/";
        }
        filePath += fileName;
        
        if (fileType === 'Directory') {
          filePath += '/';
        }
        
        $.get('delete.html?path=' + filePath)
        .done(function() {
          getDir();
        })
        .fail(function() {
          alert("Failed to delete file.");
        });
        
        $('#actions #file-actions .button').addClass('disable');
    }
  });
  
  // Rename button
  $('#rename-button').click(function() {
    if ($('#rename-button').hasClass('disable')) return;
    
    var val = $('td.selected.file-name').text().trim();
    if (val === "") {
      return;
    }
    
    modal = $('#rename-file-window').omniWindow();
    modal.trigger('show');
                            
    $('#rename-file-form #new-name').val(val).focus();

    $('.close-button').click(function(e) {
      e.preventDefault();
      modal.trigger('hide');
    });
  });
  
  // Move button
  $('#move-button').click(function() {
    if ($('#move-button').hasClass('disable')) return;
    
    var filePath = "/";
    for (var i = 1; i < path.length; i++) {
      filePath += path[i] + "/";
    }
    
    modal = $('#move-file-window').omniWindow();
    modal.trigger('show');
                            
    $('#move-file-form #new-path').val(filePath).focus();

    $('.close-button').click(function(e) {
      e.preventDefault();
      modal.trigger('hide');
    });
  });  
  
  // Open/download file button
  $('#open-button').click(function() {
    if ($('#open-button').hasClass('disable')) return;
    
    var fileName = $('td.selected.file-name').text().trim();
    var fileType = $('td.selected.file-type').text().trim();
    
    if (fileName === "") {
      return;
    }
                          
    if (fileType === 'Directory') {
      openDir(fileName);
    } else {
      var filePath = "/";
      for (var i = 1; i < path.length; i++) {
        filePath += path[i] + "/";
      }
      filePath += fileName;
      window.location.href = 'download.html?path=' + filePath;
    }
  });

  // Create new directory window
  $('#create-directory-button').click(function(e) {
    modal = $('#create-directory-window').omniWindow();
    modal.trigger('show');
    
    $('#create-directory-form #dir-name').focus();

    $('.close-button').click(function(e) {
      e.preventDefault();
      modal.trigger('hide');
    });
  });
  
  // Rename file button
  $('#rename-file-form .button').click(renameFileFromForm);
  $('#rename-file-form input').keyup(renameFileFromForm);
  
  function renameFileFromForm(e) {
    if (e.type === 'keyup' && e.which != 13) return;
    
    var fileName = $('#rename-file-form #new-name').val();
    var old = $('td.selected.file-name').text().trim();
    var type = $('td.selected.file-type').text().trim();
    
    if (old === "") {
      return;
    }
    
    if (type === 'Directory') {
      old += '/';
      if (fileName[path.length - 1] !== '/') {
        fileName += '/';
      }
      if((fileName.split("/").length - 1) > 1) {
        alert("Error invalid name");
        return;
      }

    }
    else {
      if((fileName.split("/").length - 1) >= 1) {
        alert("Error invalid name");
        return;
      }
    }
  
    $('#rename-file-form #new-name').val("");

    renameFile(old, fileName);
    modal.trigger('hide');
  }
  
  // Move file button
  $('#move-file-form .button').click(moveFileFromForm);
  $('#move-file-form input').keyup(moveFileFromForm);
  
  function moveFileFromForm(e) {
    if (e.type === 'keyup' && e.which != 13) return;

    var newPath = $('#move-file-form #new-path').val();
    var old = $('td.selected.file-name').text().trim();
  
    var lastComponent = newPath.substr(newPath.lastIndexOf('/') + 1)
  
    if ( (newPath[newPath.length - 1] !== "/") ){
        if ( (newPath.split("/").length - 1) <= 1 ){
            alert("Error: You're trying to move a file using Rename.");
            return;
        }
    }
  
    if (old === "") {
      return;
    }
  

  // Changing open button label to "Download" or "Open" depending on its type.
  var fileType = $('td.selected.file-type').text().trim();
  var filePath = "/";
  for (var i = 1; i < path.length; i++) {
    filePath += path[i] + "/";
  }
  
  if (fileType === "Directory") {
    newPath += old;
    newPath += "/";
    old = filePath + old+"/";
  }else if (fileType === "File") {
  
  if (newPath[newPath.length -1] == "/")
    newPath += old;
    old = filePath + old;
  }else{
    return;
  }
    moveFile(old, newPath);
    modal.trigger('hide');
  }
  
  // Create new directory button
  $('#create-directory-form .button').click(createDirFromForm);
  $('#create-directory-form input').keyup(createDirFromForm);
  
  function createDirFromForm(e) {
    if (e.type === 'keyup' && e.which != 13) return;
    
    var dirName = $('#create-directory-form #dir-name').val();
    $('#create-directory-form #dir-name').val("");
    
    createDir(dirName);
    modal.trigger('hide');
  }

  function rebuildFileList() {
    $('#file-list tr').not('[id~="header-row"]').remove();
    $('#actions #file-actions .button').addClass('disable');

    if (sortFunc != null) {
      cwd.sort(compareName);
      cwd.sort(sortFunc);
    }

    for (var file in cwd) {
      var entry = cwd[file];
      var rowClass = '';
      var size = '';
  
      if (entry.type === "Directory") {
        rowClass = 'directory';
        entry.modified = "";
      } else {
        if ( !isNaN(entry.modified ) )
            entry.modified = new Date(entry.modified * 1000).format("Y-m-d H:i:s");
        size = entry.size + ' bytes';
      }

      var row = '<tr class="' + rowClass + '">'
              + '  <td class="file-name"><img src="img/type_' + entry.icon + '.png" /> ' + entry.name + '</td>'
              + '  <td class="file-modified">' + entry.modified + '</td>'
              + '  <td class="file-type">' + entry.type + '</td>'
              + '  <td class="file-size">' + size + '</td>'
              + '</tr>';

      $('#file-list').contents().append(row);
    }
  }
  
  function renameFile(oldFile, newFile) {
    if (oldFile === newFile || newFile === '' || newFile === ' ') return;
    
    var filePath = "/";
    for (var i = 1; i < path.length; i++) {
      filePath += path[i] + "/";
    }
    
    oldPath = filePath + oldFile;
    newPath = filePath + newFile;

    $.get('rename.html?old=' + oldPath + '&new=' + newPath)
    .done(function() {
      getDir();
      rebuildFileList();
    })
    .fail(function() {
      alert("Failed to rename file.");
    });
  }
  
  function moveFile(oldFile, newPath) {
    if (oldFile === '' || newPath === '') return;
    /*
    var filePath = "/";
    for (var i = 1; i < path.length; i++) {
      filePath += path[i] + "/";
    }
    
    oldPath = filePath + oldFile;
    newPath = newPath + oldFile;
     */
    $.get('move.html?old=' + oldFile + '&new=' + newPath)
    .done(function() {
      getDir();
      rebuildFileList();
    })
    .fail(function() {
      alert("Failed to move file.");
    });
  } 
  
  function openDir(dirName) {
    $('#actions #file-actions .button').addClass('disable');
    path.push(dirName);
    getDir();
  }
  
  function createDir(dirName) {
    var dirPath = "/";
    for (var i = 1; i < path.length; i++) {
      dirPath += path[i] + "/";
    }
    dirPath += dirName + "/";
    $.get("createDir.html?path=" + dirPath)
    .done(function() {
      getDir();
    })
    .fail(function() {
      alert("Failed to create directory.");
    });
  }
  
  function getDir() {
    var dirPath = "/";
    for (var i = 1; i < path.length; i++) {
      dirPath += path[i] + "/";
    }
    $.get("directory.json?path=" + dirPath, function(data) {
      var newHash = contentsToStr(data.contents);
      
      if (newHash === cwdHash) return;
      
      cwd = data.contents;
      cwdHash = newHash;
      
      for (var i = 0; i < cwd.length; i++) {
        var filename = cwd[i].name;
        if (filename.charAt(filename.length - 1) === "/") {
          cwd[i].name = filename.slice(0, filename.length - 1);
          cwd[i].type = "Directory";
          cwd[i].icon = "directory";
        } else {
          cwd[i].type = "File";
          cwd[i].icon = "file";
        }
      }
      rebuildFileList();
      rebuildBreadCrumbs();
    });
  }

  function rebuildBreadCrumbs() {
    var html = '<img src="img/page_link.png" /> ';
    var sep = '';
    for (var i = 0; i < path.length; i++) {
      var bcPath = path[i];
      if (path[i] === "/") {
        bcPath = "root";
      }
      html += sep + '<a href="#" id="bc' + i + '">' + bcPath + '</a>'
      sep = ' / ';
    }
    $('#breadcrumbs').html(html);
  }

  function compareName(a, b) {
    if (a.name < b.name) {
      return -1;
    }
    return 1;
  }

  function compareDate(a, b) {
    if (a.modified < b.modified) {
      return -1;
    } else if (a.modified > b.modified) {
      return 1;
    }
    return 0;
  }

  function compareType(a, b) {
    if (a.type < b.type) {
      return -1;
    } else if (a.type > b.type) {
      return 1;
    }
    return 0;
  }

  function compareSize(a, b) {
    if (a.size < b.size) {
      return -1;
    } else if (a.size > b.size) {
      return 1;
    }
    return 0;
  }
  
  function uploadProgress(e) {
    if (e.lengthComputable) {
      var percent = e.loaded / e.total * 100;
      $('#upload-progress > div').css('width', percent + '%');
    }
  }
  
  function clearProgressBar() {
    $('#upload-progress > div').css('width', '0');
    $('#upload-progress > div').text('');
  }
  
  function contentsToStr(contents) {
    var str = "#<DirContents [";
    for (var i = 0; i < contents.length; i++) {
      if (i != 0) {
        str += ","
      }
      
      str += "{";
      
      var sep = "";
      for (key in contents[i]) {
        var val = contents[i][key];
        if (val === "") {
          val = "null";
        }
        str += sep + key + ":" + val;
        sep = ",";
      }
      str += "}"
    }
    str += "]>";
    
    return str;
  }
  
  setInterval(getDir, 3000);
});
