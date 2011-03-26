Ext.ns("Compass.ErpApp.Desktop.Applications");

Compass.ErpApp.Desktop.Applications.FileManager  = Ext.extend(Ext.app.Module, {
    id:'file_manager-win',

    setWindowStatus : function(status){
        this.win.setStatus(status);
    },
    
    clearWindowStatus : function(){
        this.win.clearStatus();
    },

    init : function(){
        this.launcher = {
            text: 'File Manager',
            iconCls:'icon-folders',
            handler : this.createWindow,
            scope: this
        }
    },
    createWindow : function(){
        var self = this;
        var desktop = this.app.getDesktop();
        var win = desktop.getWindow('file_manager');
        if(!win){

            var contentCardPanel = new Ext.Panel({
                layout:'card',
                autoDestroy:true,
                frame:false,
                border:false,
                region:'center'
            })
			
            var fileTreePanel = new Compass.ErpApp.Shared.FileManagerTree({
                xtype:'compassshared_filemanager',
                allowDownload:true,
                addViewContentsToContextMenu:true,
                region:'west',
                rootVisible:true,
                loader: new Ext.tree.TreeLoader({
                    dataUrl:'./file_manager/base/expand_directory'
                }),
                containerScroll: true,
                standardUploadUrl:'./file_manager/base/upload_file',
                xhrUploadUrl:'./file_manager/base/upload_file',
                border: false,
                width: 250,
                height: 300,
                frame:true,
                listeners:{
                    'contentLoaded':function(fileManager, node, content){
                        var path = node.id;
                        var fileType = path.split('.').pop();
                        contentCardPanel.removeAll(true);
                        contentCardPanel.add({
                            disableToolbar:!ErpApp.Authentication.RoleManager.hasRole('admin'),
                            xtype:'codemirror',
                            parser:fileType,
                            sourceCode:content,
                            listeners:{
                                'save':function(codeMirror, content){
                                    self.setWindowStatus('Saving...');
                                    var conn = new Ext.data.Connection();
                                    conn.request({
                                        url: './file_manager/base/update_file',
                                        method: 'POST',
                                        params:{
                                            node:path,
                                            content:content
                                        },
                                        success: function(response) {
                                            var obj =  Ext.util.JSON.decode(response.responseText);
                                            if(obj.success){
                                                self.clearWindowStatus();
                                            }
                                        },
                                        failure: function(response) {
                                            self.clearWindowStatus();
                                            Ext.Msg.alert('Error', 'Error saving content');
                                        }
                                    });
                                }
                            }
                        });
                        contentCardPanel.getLayout().setActiveItem(0);
                    }
                }
            }
            );

            win = desktop.createWindow({
                id: 'file_manager',
                title:'File Manager',
                width:1000,
                height:550,
                autoDestroy:true,
                iconCls: 'icon-folders',
                shim:false,
                animCollapse:false,
                constrainHeader:true,
                layout: 'border',
                items:[fileTreePanel,contentCardPanel],
                listeners:{
                    'destroy':function(){
                        fileTreePanel.destroy();
                        contentCardPanel.destroy();
                    }
                }
            });

            this.win = win;
        }
        win.show();
        fileTreePanel.root.expand();
    }
});
