require_relative '../lib/rsync_git_manager'

class FsViewerTabWidget < Qt::TabWidget

  attr_accessor :start

  def initialize *args
    super *args

    @icons = Qt::FileIconProvider.new

    @layout = Qt::GridLayout.new
    setLayout @layout

    @rsync = Qt::PushButton.new "Rsync + Git"
    @layout.addWidget @rsync, 0,0
    @rsync.connect(SIGNAL :released) {
      @manager.sync_new_revision

    }

    @open_folder = Qt::PushButton.new "Open Folder"
    @layout.addWidget @open_folder, 0,1

    @open_folder.connect(SIGNAL :released) {
      Launchy.open @local_path

    }

    @open_gitk = Qt::PushButton.new "Open gitk"
    @layout.addWidget @open_gitk, 0,2

    @open_gitk.connect(SIGNAL :released) {
      Process.spawn "(cd #{@local_path} && gitk)"
    }



    @treeview = Qt::TreeWidget.new
    @treeview.connect(SIGNAL('itemExpanded(QTreeWidgetItem*)')) { |dir|
      add_dirs dir, dir.text(1)
    }


#    @treeview.connect(SIGNAL('itemPressed(QTreeWidgetItem*, int)')) { |dir|
#      @selected_dir = dir.text(1)
#      populate_files dir.text(1)
#    }

    selection = @treeview.selectionModel()
    selection.connect(SIGNAL('selectionChanged(QItemSelection,QItemSelection)')) {|x,y|
      unless @treeview.selectedItems.length == 0
        item = @treeview.selectedItems[0]
        @selected_dir = item.text(1)
        populate_files item.text(1)
      end
    }


    @file_details = Qt::GroupBox.new self
    @file_details.setTitle "Details"
    @file_details_layout = Qt::GridLayout.new
    @file_details.setLayout @file_details_layout

    @file_details_file =  Qt::Label.new ""
#
    @file_details_user_label =  Qt::Label.new "<b>User</b>"
    @file_details_user =  Qt::Label.new ""
    @file_details_group_label =  Qt::Label.new "<b>Group</b>"
    @file_details_group =  Qt::Label.new ""
    @file_details_permissions_label = Qt::Label.new "<b>Permission</b>"
    @file_details_permissions = Qt::Label.new ""
    @file_details_protection_label =  Qt::Label.new "<b>Protection Class</b>"
    @file_details_protection =  Qt::Label.new ""
    @file_details_layout.addWidget @file_details_file

    @file_details_layout.addWidget @file_details_file, 0, 0, 1, 2
    @file_details_layout.addWidget @file_details_user_label, 1, 0
    @file_details_layout.addWidget @file_details_user, 1, 1
    @file_details_layout.addWidget @file_details_group_label, 2, 0
    @file_details_layout.addWidget @file_details_group, 2, 1
    @file_details_layout.addWidget @file_details_permissions_label, 3, 0
    @file_details_layout.addWidget @file_details_permissions, 3, 1
    @file_details_layout.addWidget @file_details_protection_label, 4, 0
    @file_details_layout.addWidget @file_details_protection, 4, 1
    @file_details_layout.addItem Qt::SpacerItem.new(0,1, Qt::SizePolicy::Expanding, Qt::SizePolicy::Fixed ), 0, 2
    @layout.addWidget @file_details, 2, 0, 1, 3
    @file_details.setSizePolicy(Qt::SizePolicy::Minimum, Qt::SizePolicy::Minimum)



    @model = Qt::StandardItemModel.new

    @selection_model = Qt::ItemSelectionModel.new @model


    @file_list = Qt::TableView.new
    @file_list.setModel @selection_model.model
    @file_list.setSelectionModel(@selection_model)
    @file_list.setSelectionBehavior(Qt::AbstractItemView::SelectRows)
    @file_list.setEditTriggers(Qt::AbstractItemView::NoEditTriggers	)
    @file_list.setSizePolicy(Qt::SizePolicy::Expanding,Qt::SizePolicy::Expanding);

    @splitter = Qt::Splitter.new
    @splitter.addWidget @treeview
    @splitter.addWidget @file_list
    @splitter.setStretchFactor 1, 1.5
    @splitter.setSizePolicy(Qt::SizePolicy::Expanding, Qt::SizePolicy::Expanding)
    @layout.addWidget @splitter, 1, 0, 1, 3



    @file_list.connect(SIGNAL('doubleClicked(QModelIndex)')) {|x|
      cache_name =  $selected_app.cache_file  "#{@selected_dir}/#{@model.item(x.row,0).text}"
      if cache_name.nil?
        $log.error "File #{@selected_dir}/#{@model.item(x.row,0).text} could not be downloaded. Either the file does not exist (e.g., dead symlink) or there is a permission problem."
      else
        $device.ops.open cache_name
      end
    }

    @selection_model.connect(SIGNAL('selectionChanged(QItemSelection,QItemSelection)')) {|x,y|
      unless x.indexes.length == 0
        # for icon if desired
#        tmp_file = Qt::TemporaryFile.new "XXXXXX#{d.name}"
#        tmp_file.open
#        puts tmp_file.fileName
        row = x.indexes[0].row
        filename = @model.item(row,0).text
        @file_details_file.text = "#{@selected_dir}/#{filename}"
        @file_details_user.text = @model.item(row,3).text
        @file_details_group.text = @model.item(row,4).text
        @file_details_permissions.text = @model.item(row,2).text
        @file_details_protection.text = $device.protection_class "#{@selected_dir}/#{filename}"
      end
    }
  end

  def populate_files path
    @model.clear
    @model.setHorizontalHeaderItem(0, Qt::StandardItem.new("filename"))
    @model.setHorizontalHeaderItem(1, Qt::StandardItem.new("size"))
    @model.setHorizontalHeaderItem(2, Qt::StandardItem.new("permissions"))
    @model.setHorizontalHeaderItem(3, Qt::StandardItem.new("uid"))
    @model.setHorizontalHeaderItem(4, Qt::StandardItem.new("gid"))

    dirs = $device.ops.list_dir_full path
    dirs.each { |d|
      unless d.directory?
        row = Array.new
        row << Qt::StandardItem.new(d.name)
        size = d.attributes.size rescue ""
        row << Qt::StandardItem.new(size.to_s)
        perms = d.attributes.permissions rescue ""
        row << Qt::StandardItem.new(perms.to_s)
        owner = d.attributes.uid # rescue d.attributes.uid
        row << Qt::StandardItem.new(owner.to_s)
        group = d.attributes.gid # rescue d.attributes.gid
        row << Qt::StandardItem.new(group.to_s)
        @model.appendRow(row)
      end
    }
    @file_list.resizeColumnsToContents
    @file_list.resizeRowsToContents

  end



  def add_dirs parent, cur_dir
    dirs = $device.ops.list_dir_full cur_dir
    dirs.each { |d|
      if d.name != "." and d.name != ".."
        full_path = "#{cur_dir}/#{d.name}"
        if d.directory?
          node = addChild parent, d.name, full_path, true
        end
      end
    }

  end

  def refresh
    add_dirs @root_node, @start


  end



  def addChild(parent, child_text, path,  expandable)
    tree_item = Qt::TreeWidgetItem.new
    tree_item.setText(0, child_text)
    tree_item.setText(1, path)
    parent.addChild tree_item
    if expandable
      tree_item.setChildIndicatorPolicy(Qt::TreeWidgetItem::ShowIndicator)
    end
    tree_item
  end

  def set_start start
    @treeview.clear
    @root_node = Qt::TreeWidgetItem.new
    @root_node.setText(0, "app root")
    @root_node.setChildIndicatorPolicy(Qt::TreeWidgetItem::ShowIndicator)
    @treeview.addTopLevelItem @root_node
    @start = start
    @selected_dir = start
    @root_node.setText(1, @start)
    @local_path = "#{$selected_app.cache_dir}/idb_mirror.git"
    @manager = RsyncGitManager.new start, @local_path
  end

end