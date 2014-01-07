class AppListDialog < Qt::Dialog
  attr_accessor :app_list

  def initialize *args
    super *args

    setWindowTitle("App Selection")
    @layout = Qt::GridLayout.new
    setLayout(@layout)

    @app_list = Qt::ListWidget.new self
    @app_list.setSortingEnabled(true);
    @app_list.connect(SIGNAL('itemDoubleClicked(QListWidgetItem*)')) { |item|
      emit accept
    }
    @layout.addWidget @app_list, 0, 0, 1, 2

    refresh_app_list


    @save_button = Qt::PushButton.new "Select"
    @save_button.setDefault true

    @save_button.connect(SIGNAL(:released)) {|x|
      accept()
    }
    @cancel_button = Qt::PushButton.new "Cancel"
    @cancel_button.connect(SIGNAL(:released)) {|x|
      reject()
    }

    @layout.addWidget @save_button, 1, 1
    @layout.addWidget @cancel_button, 1, 0

    setFixedHeight(500);
    setFixedWidth(400);


  end

  def refresh_app_list
    app_uuids =  $device.get_app_uuids
    progress = Qt::ProgressDialog.new "Reading App list...", nil, 1, app_uuids.size, self
    progress.setAutoClose true
    progress.setWindowModality(Qt::WindowModal);
    progress.show
    progress.raise


    app_uuids.each { |uuid|
      a = App.new uuid

      i = AppListWidgetItem.new @app_list, 0
      i.setText a.bundle_id
      i.app = a
      @app_list.add_item i
      progress.setValue(progress.value+1);


    }
  end


end