$.uce.widget("fileupload", {
    options: {
        ucemeeting : null,
        upload     : true,
        title      : "Files",
        mode       : "expanded"
    },

    // ucengine events
    meetingsEvents: {
        'internal.file.add'           : '_handleFileAddEvent',
        'document.conversion.done'    : '_handleFileDocumentEvent'
    },

    _create: function() {
        var that = this;

        this.element.addClass('ui-widget ui-fileupload');
        this._addHeader(this.options.title, this.options.buttons);

        var all = $('<div>').attr('class', 'ui-fileupload-all');
        var preview = $('<div>').attr('class', 'ui-fileupload-preview');
        // init preview content
        $('<div>').attr('class', 'ui-fileupload-preview-title').appendTo(preview);
        var toolbar = $('<div>').attr('class', 'ui-corner-all ui-preview-toolbar');

        var previous = $('<span>')
            .attr('class', 'ui-fileupload ui-toolbar-button ui-button-previous')
            .attr('href', '#')
            .button({
                text: false,
                icons: {
                    primary: "ui-icon-arrowthick-1-n"
                }
            });

        var next = $('<span>')
            .attr('class', 'ui-fileupload ui-toolbar-button ui-button-next')
            .attr('href', '#')
            .button({
                text: false,
                icons: {
                    primary: "ui-icon-arrowthick-1-s"
                }
            });

        previous.appendTo(toolbar);
        next.appendTo(toolbar);

        var pageSelector = $('<span>').attr('class', 'ui-fileupload ui-toolbar-selector');
        $('<span>').attr('class', 'ui-fileupload ui-selector-current')
            .appendTo(pageSelector);
        $('<span>').attr('class', 'ui-fileupload ui-selector-separator').text('/')
            .appendTo(pageSelector);
        $('<span>').attr('class', 'ui-fileupload ui-selector-total')
            .appendTo(pageSelector);
        pageSelector.appendTo(toolbar);

        var stop = $('<span>')
            .attr('class', 'ui-fileupload ui-toolbar-button ui-button-stop')
            .attr('href', '#')
            .button({
                text: false,
                icons: {
                    primary: "ui-icon-circle-close"
                }
            });

        stop.appendTo(toolbar);

        toolbar.appendTo(preview);
        var pageContainer = $('<div>').attr('class', 'ui-fileupload-preview-page').appendTo(preview);
        $('<img>').appendTo(pageContainer);

        previous.bind('click', function() {
            if (that.currentPreview) {
                if (that.currentPreview.currentPage>0)
                    that.currentPreview.currentPage--;
                var page = that.currentPreview.currentPage;
                that._preview(that.currentPreview);
            }
            return false;
        });
        next.bind('click', function() {
            if (that.currentPreview) {
                if (that.currentPreview.currentPage<that.currentPreview.pages.length-1)
                    that.currentPreview.currentPage++;
                var page = that.currentPreview.currentPage;
                that._preview(that.currentPreview);
            }
            return false;
        });
        stop.bind('click', function() {
            that.currentPreview = null;
            that.viewAll();
            that._setTitle(that.options.title);
            return false;
        });

        var content = $('<div>').attr('class', 'ui-widget-content').appendTo(this.element);
        all.appendTo(content);
        preview.appendTo(content);
        this.viewAll();
        $('<ul>').attr('class', 'ui-fileupload-list').appendTo(all);
        this._listFiles = [];
        this._shared = null;
        if (this.options.ucemeeting) {
            if (this.options.upload) {
                var uploadButton = $('<a>').attr('href', '#')
                    .button({label: "Upload New File"})

                var uploadContainer = $('<div>').append($('<p>').attr('class', 'ui-fileupload-add')
                                                        .append(uploadButton)).appendTo(all);
                new AjaxUpload(uploadContainer.find('a'), {
                    action: this.options.ucemeeting.getFileUploadUrl(),
                    name: 'content',
                    onComplete : function(file, response){
                        return true;
                    }
                });
            }
        }

        /* create dock */
        if (this.options.dock) {
            this._dock = dock = $('<a>')
                .attr('class', 'ui-dock-button')
                .attr('href', '#')
                .attr('title', this.options.title)
                .button({
                    text: false,
                    icons: {primary: "ui-icon-document"}
                }).click(function() {
                    that.element.effect('bounce');
                    $(window).scrollTop(that.element.offset().top);
                    return false;
                });
            this._dock.addClass('ui-fileupload-dock');
            this._dock.appendTo(this.options.dock);

            this._startCount = new Date().getTime();
            this._newCount = 0;

            this._new = $('<div>')
                .attr('class', 'ui-widget-dock-notification')
                .text(this._newCount)
                .appendTo(this._dock);

            this._updateNotifications();

            all.bind('mouseover', function() {
                that._newCount = 0;
                that._updateNotifications();
            });
        }
    },

    clear: function() {
        this.element.find('.ui-fileupload-new').text(this._nbNewFiles);
        this._listFiles = [];
        this._refreshListFiles();
    },

    viewAll: function() {
        this.element.find('.ui-fileupload-all').show();
        this.element.find('.ui-fileupload-preview').hide();
    },

    viewPreview: function() {
        this.element.find('.ui-fileupload-all').hide();
        this.element.find('.ui-fileupload-preview').show();
    },

    _setOption: function(key, value) {
        $.Widget.prototype._setOption.apply(this, arguments);
        switch (key) {
        case 'upload':
            this.element.find('.ui-fileupload-add').toggle();
            break;
        }
    },

    /**
     *  Modes
     */
    reduce: function() {
        this.options.mode = "reduced";
    },

    expand: function() {
        this.options.mode = "expanded";
    },

    _handleFileAddEvent: function(event) {
        if (event.from == "document") {
            return;
        }

        if (event.datetime > this._startCount) {
            this._newCount++;
            this._updateNotifications();
        }

        this._listFiles.push($.extend({}, event, {pages: []}));
        this._refreshListFiles();
    },

    _handleFileDocumentEvent: function(event) {
        $(this._listFiles).each(
            function(index, file) {
                if (file.id == event.parent) {
                    for (var key in event.metadata) {
                        var value = event.metadata[key];
                        file.pages[key] = value;
                    };
                }
            }
        );
        this._refreshListFiles();
    },

    _refreshListFiles: function() {
        var ul = $();
        var ucemeeting = this.options.ucemeeting;
        var that = this;
        $(this._listFiles).each(
            function(index, file) {
                var id = file.metadata.id;
                var mimes = { 'application/pdf'     : 'pdf'
                        , 'image/gif'           : 'image'
                        , 'image/png'           : 'image'
                        , 'image/jpeg'          : 'image'
                        , 'video/mpeg'          : 'video'
                        , 'video/mp4'           : 'video'
                        , 'video/ogg'           : 'video'
                        //, 'video/x-flv'         : 'video'
                        //, 'video/quicktime'     : 'video'
                        //, 'video/x-ms-wmv'      : 'video'
                        //, 'video/x-ms-msvideo'  : 'video'
                        };
                var mime = (file.metadata.mime in mimes) ? mimes[file.metadata.mime] : 'default';
                var filename = $('<a>').text(file.metadata.name)
                                       .attr('href', '#')
                                       .attr('class', 'ui-fileupload ui-preview-link');

                var date = $.strftime("%m-%d-%y", file.datetime);
                var fileowner = $('<span>').attr('class', 'ui-file-owner')
                                           .text(" " + date + " by " + file.from);

                var downloadLink = $('<a>').attr('href', ucemeeting.getFileDownloadUrl(id))
                                           .text('Download')
                                           .attr('class', 'ui-fileupload ui-download-link');

                var li = $('<li>').attr('class', 'mime ' + mime);
                $('<p>').append(filename).appendTo(li);
                $('<p>').append(fileowner).appendTo(li);

                if (file.pages.length != 0) {
                        viewLink = $('<a>').attr('href', '#')
                                           .text('Open in the viewer')
                                           .bind('click', function() {
                                                if (! file.currentPage)
                                                    file.currentPage = 0;
                                                that._preview(file);
                                                that.viewPreview(); 
                                                return false; })
                                           .attr('class', 'ui-fileupload ui-preview-link');

                        shareLink = $('<a>').attr('href', '#')
                                            .text('Share')
                                            .bind('click', function() {
                                                that.options.ucemeeting.push("document.share.start", {id: file.metadata.id});
                                                return false; })
                                            .attr('class', 'ui-fileupload ui-share-link');

                    $('<p>').append(downloadLink).append(' | ').append(viewLink).append(' | ').append(shareLink).appendTo(li);
                }
                else {
                        if (mime == "default") {
                            $('<p>').append(downloadLink).appendTo(li);
                        }
                        else {
                            if (mime == "image")
                                viewLink = $('<a>').attr('href', '#')
                                                   .text('Open in the viewer')
                                                   .bind('click', function() {
                                                        that._previewImage(file); 
                                                        that.viewPreview(); 
                                                        return false; })
                                                   .attr('class', 'ui-fileupload ui-preview-link');
                            else if (mime == "video")
                                viewLink = $('<a>').attr('href', '#')
                                                   .text('Open in the viewer')
                                                   .bind('click', function() {
                                                        that._previewVideo(file); 
                                                        that.viewPreview(); 
                                                        return false; })
                                                   .attr('class', 'ui-fileupload ui-preview-link');
                            shareLink = $('<a>').attr('href', '#')
                                .text('Share')
                                .bind('click', function() {
                                    that.options.ucemeeting.push("document.share.start", {id: file.metadata.id});
                                    return false; })
                                .attr('class', 'ui-fileupload ui-share-link');
                            $('<p>').append(downloadLink).append(' | ').append(viewLink).append(' | ').append(shareLink).appendTo(li);
                        }
                }
                ul = ul.add(li);
            }
        );
        this.element.find('.ui-fileupload-list').empty().append(ul);
    },

    _preview: function(file) {
        this._setTitle(file.metadata.name);
        var preview = this.element.find('.ui-fileupload-preview');
        this.element.find('.ui-fileupload-preview-page video').hide();
        this.element.find('.ui-fileupload-preview-page img').show();
        this.element.find('.ui-button-previous').show(); 
        this.element.find('.ui-button-next').show(); 
        this.element.find('.ui-toolbar-selector').show();
        this.element.find('.ui-selector-current')
            .text(file.currentPage + 1);
        this.element.find('.ui-selector-total')
            .text(file.pages.length);
        var pageImg = this.element.find('.ui-fileupload-preview-page img');
        var src = this.options.ucemeeting
            .getFileDownloadUrl(file.pages[file.currentPage]);
        pageImg.attr('src', src);
        this.currentPreview = file;
    },

    _previewImage: function(file) {
        this._setTitle(file.metadata.name);
        var preview = this.element.find('.ui-fileupload-preview');
        this.element.find('.ui-fileupload-preview-page img').show();
        this.element.find('.ui-fileupload-preview-page video').hide();
        this.element.find('.ui-button-previous').show(); 
        this.element.find('.ui-button-next').show(); 
        this.element.find('.ui-toolbar-selector').show();
        this.element.find('.ui-selector-current')
            .text(1);
        this.element.find('.ui-selector-total')
            .text(1);
        var pageImg = this.element.find('.ui-fileupload-preview-page img');
        var src = this.options.ucemeeting
                      .getFileDownloadUrl(file.metadata.id);
        pageImg.attr('src', src);
    },

    _previewVideo: function(file) {
        this._setTitle(file.metadata.name);
        var preview = this.element.find('.ui-fileupload-preview');
        this.element.find('.ui-fileupload-preview-page img').hide();
        this.element.find('.ui-button-previous').hide(); 
        this.element.find('.ui-button-next').hide(); 
        this.element.find('.ui-toolbar-selector').hide();
        this.element.find('.ui-selector-current')
            .text(1);
        this.element.find('.ui-selector-total')
            .text(1);
        var pageVideo = this.element.find('.ui-fileupload-preview-page');
        pageVideo.html("");
        var src = this.options.ucemeeting
                      .getFileAlternativeDownloadUrl(file.metadata.id);
        var video = $('<video controls autoplay width="100%">').attr('display', 'block');
                                //.attr('controls', true)
                                //.attr('autoplay', true)
                                //.attr('width', "100%")
                                //.attr('display', 'block');
        $('<source>').attr('type','video/mp4')
                     .attr('src',src) 
                     .appendTo(video);
        var object = $('<object>').attr('type','application/x-shockwave-flash')
                                  .attr('data','/lib/file_upload/player.swf')
                                  .attr('src','/lib/file_upload/player.swf')
                                  .attr('width','100%')
                                  .attr('height','300px')
                                  .html("");
        //$('<param>').attr('name','movie')
        //            .attr('value','/lib/file_upload/player.swf')
        //            .appendTo(object);
        $('<param>').attr('name','allowfullscreen')
                    .attr('value','true')
                    .appendTo(object);
        $('<param>').attr('name','allowscriptaccess')
                    .attr('value','always')
                    .appendTo(object);
        $('<param>').attr('name','flashvars')
                    .attr('value',"file="+encodeURI(src))
                    .appendTo(object);
        var p = $('<p>').html("");
        object.appendTo(p);                          
        video.appendTo(p);
        /*
        $('<button>').attr('type', 'button')
                     .attr('onclick', '$(this).parent().children()[0].play()')
                     .html("lecture")
                     .appendTo(p);
        $('<button>').attr('type', 'button')
                    .attr('onclick', '$(this).parent().children()[0].pause()')
                    .html('Pause')
                    .appendTo(p);
        $('<button>').attr('type', 'button')
                    .attr('onclick', '$(this).parent().children()[0].stop()')
                    .html('Stop')
                    .appendTo(p);
        */
        p.appendTo(pageVideo);
        //console.log(pageVideo);
    },

    _updateNotifications: function() {
        this._new.text(this._newCount);
        if (this._newCount == 0) {
            this._new.hide();
        } else {
            this._new.show();
        }
    },

    destroy: function() {
        this.element.find('*').remove();
        this.element.removeClass('ui-widget ui-fileupload');
        $(this.options.dock).find('*').remove();
        $.Widget.prototype.destroy.apply(this, arguments); // default destroy
    }
});
