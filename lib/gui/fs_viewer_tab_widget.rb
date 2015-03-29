require_relative '../lib/rsync_git_manager'
module Idb

  class FSViewerControlGroupBox < Qt::GroupBox
    def initialize *args
      @layout = Qt::GridLayout.new
      super *args
      setLayout @layout

      setTitle "Rsync app folder locally and keep git revisions"


      @sync_path_label = Qt::Label.new "<b>Local Sync Path:</b>"
      @layout.addWidget @sync_path_label, 0,0, 1,3

      @sync_path_change = Qt::PushButton.new "Change Folder"
      @sync_path_change.connect(SIGNAL :released) {
        file_dialog = Qt::FileDialog.new
        file_dialog.setFileMode(Qt::FileDialog::Directory)
        file_dialog.setAcceptMode(Qt::FileDialog::AcceptOpen)
        file_dialog.connect(SIGNAL('fileSelected(QString)')) { |x|
          @local_path = x
          dir_changed
        }
        file_dialog.exec
      }

      @layout.addWidget @sync_path_change, 1,1

      @open_folder = Qt::PushButton.new "Open Folder"
      @layout.addWidget @open_folder, 1,0

      @open_folder.connect(SIGNAL :released) {
        Launchy.open @local_path

      }


      @reset_folder = Qt::PushButton.new "Use Default Folder"
      @layout.addWidget @reset_folder, 1,2

      @reset_folder.connect(SIGNAL :released) {
        update_start
      }

      line = Qt::Frame.new
      line.setFrameShape Qt::Frame::VLine
      line.setFrameShadow Qt::Frame::Sunken
      @layout.addWidget line, 0,3,2,1


      @rsync = Qt::PushButton.new "Rsync + Git"
      @layout.addWidget @rsync, 0,4
      @rsync.connect(SIGNAL :released) {
        @manager.start_new_revision
        if $device.ios_version == 8
          @manager.sync_dir $selected_app.app_dir, "app_bundle"
          @manager.sync_dir $selected_app.data_dir, "data_bundle"
        else
          @manager.sync_dir $selected_app.app_dir, "app_bundle"
        end
        @manager.commit_new_revision

      }


      @open_gitk = Qt::PushButton.new "Open gitk"
      @layout.addWidget @open_gitk, 1,4

      @open_gitk.connect(SIGNAL :released) {
        Process.spawn "(cd #{@local_path} && gitk)"
      }


    end

    def update_start
      @selected_dir = $selected_app.app_dir
      @local_path = "#{$selected_app.cache_dir}/idb_mirror.git"
      dir_changed
    end

    def dir_changed
      @sync_path_label.setText "<b>Local Sync Path:</b> " + @local_path
      @manager = RsyncGitManager.new @local_path
    end




  end


  class FsViewerTabWidget < Qt::TabWidget

    attr_accessor :start

    def initialize *args
      super *args

      @icons = Qt::FileIconProvider.new

      @layout = Qt::GridLayout.new
      setLayout @layout

      @controls = FSViewerControlGroupBox.new self
      layout.addWidget @controls, 0, 0, 1, 2



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

      @default_protection = DefaultProtectionClassGroupWidget.new self
      @layout.addWidget @default_protection, 3, 0, 1, 3
      @file_details.setSizePolicy(Qt::SizePolicy::Minimum, Qt::SizePolicy::Minimum)


      @refresh_tree = Qt::PushButton.new "Refresh"
      @refresh_tree.connect(SIGNAL :released) {
        update_start
      }

      @model = Qt::StandardItemModel.new

      @selection_model = Qt::ItemSelectionModel.new @model


      @file_list = Qt::TableView.new
      @file_list.setModel @selection_model.model
      @file_list.setSelectionModel(@selection_model)
      @file_list.setSelectionBehavior(Qt::AbstractItemView::SelectRows)
      @file_list.setEditTriggers(Qt::AbstractItemView::NoEditTriggers	)
      @file_list.setSizePolicy(Qt::SizePolicy::Expanding,Qt::SizePolicy::Expanding);

      @tree_widget = Qt::Widget.new
      @tree_widget_layout = Qt::VBoxLayout.new
      @tree_widget.setLayout @tree_widget_layout
      @tree_widget_layout.add_widget @treeview
      @tree_widget_layout.add_widget @refresh_tree

      @splitter = Qt::Splitter.new
      @splitter.addWidget @tree_widget
      @splitter.addWidget @file_list
      @splitter.setStretchFactor 1, 1.5
      @splitter.setSizePolicy(Qt::SizePolicy::Expanding, Qt::SizePolicy::Expanding)
      @layout.addWidget @splitter, 1, 0



      @file_list.connect(SIGNAL('doubleClicked(QModelIndex)')) {|x|
        cache_name =  $selected_app.cache_file  "#{@selected_dir}/#{@model.item(x.row,0).text}"
        if cache_name.nil?
          $log.error "File #{@selected_dir}/#{@model.item(x.row,0).text} could not be downloaded. Either the file does not exist (e.g., dead symlink) or there is a permission problem."
        else
          unless $device.ops.open cache_name
            error = Qt::MessageBox.new
            error.setInformativeText("Could not open file #{cache_name}. Likely there is no app registered for this file type. See log for more details.")
            error.setIcon(Qt::MessageBox::Critical)
            error.exec

          end
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

      unless $device.ops.file_exists? path
        reply = Qt::MessageBox::critical(self, "Directory not found", "Could not open directory #{path}. The selected directory no longer exists on the target device.\n\nDo you want to reload the directory tree?", Qt::MessageBox::Yes, Qt::MessageBox::No)
        if reply == Qt::MessageBox::Yes
          update_start
          return
        else
          return
        end
      end
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
      if parent.text(2) == "true"
        # we added children for this already
        return
      end
      parent.setText(2, "true")
      dirs = $device.ops.list_dir_full cur_dir
      dirs.each { |d|
        if d.name != "." and d.name != ".."
          full_path = "#{cur_dir}/#{d.name}"
          if d.directory?
            dirs = $device.ops.list_dir_full full_path
            expandable = has_subdirs? full_path
            node = addChild parent, d.name, full_path, expandable
          end
        end
      }
    end

    def has_subdirs? dir
      files = $device.ops.list_dir_full dir
      if files.length == 2
        # only "." and ".."
        return false
      else
        files.each { |f|
          if f.name != "." and f.name != ".." and f.directory?
            return true
          end
        }
      end
      return false
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
      else
        tree_item.setChildIndicatorPolicy(Qt::TreeWidgetItem::DontShowIndicator)
      end
      tree_item
    end

    def update_start
      @treeview.clear
      @default_protection.update

      @controls.update_start

      if $device.ios_version == 8
        start_ios_8
      else
        start_ios_pre8
      end
    end


    def start_ios_pre8
      @root_node = Qt::TreeWidgetItem.new
      @root_node.setText(0, "[App Bundle]")
      @root_node.setChildIndicatorPolicy(Qt::TreeWidgetItem::ShowIndicator)
      @treeview.addTopLevelItem @root_node
      @root_node.setText(1, $selected_app.app_dir)
    end

    def start_ios_8
      @bundle_root_node = Qt::TreeWidgetItem.new
      @bundle_root_node.setText(0, "[App Bundle]")
      @bundle_root_node.setChildIndicatorPolicy(Qt::TreeWidgetItem::ShowIndicator)
      @bundle_root_node.setText(1, $selected_app.app_dir)

      @data_root_node = Qt::TreeWidgetItem.new
      @data_root_node.setText(0, "[Data Dir]")
      @data_root_node.setChildIndicatorPolicy(Qt::TreeWidgetItem::ShowIndicator)
      @data_root_node.setText(1, $selected_app.data_dir)

      @treeview.addTopLevelItem @bundle_root_node
      @treeview.addTopLevelItem @data_root_node
    end

  end
end