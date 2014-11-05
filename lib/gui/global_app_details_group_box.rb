
module Idb
  class GlobalAppDetailsGroupBox < Qt::GroupBox
    signals "app_changed()"

    def initialize *args
      super *args

      # details on selected app
      @layout = Qt::GridLayout.new
      setLayout(@layout)
      setTitle "Selected Application"

      @app = Qt::Label.new  "<b>Connect to a device first.</b>", self, 0
      @layout.addWidget @app, 0, 0

      @app_details = Qt::Widget.new
      @app_details_layout = Qt::GridLayout.new
      @app_details_layout.setContentsMargins(0,0,0,0)

      @app_details.setLayout(@app_details_layout)

      @icon = Qt::Label.new
      @app_details_layout.addWidget @icon, 0, 0, 2,1

      @selected_app_label = Qt::Label.new  "<b>Selected App:</b>"
      @selected_app = Qt::Label.new  ""
      @app_details_layout.addWidget @selected_app_label, 0, 1
      @app_details_layout.addWidget @selected_app, 0,2

      @uuid_label = Qt::Label.new  "<b>UUID:</b>"
      @uuid = Qt::Label.new  ""
      @app_details_layout.addWidget @uuid_label, 1, 1
      @app_details_layout.addWidget @uuid, 1,2

      @layout.addWidget @app_details, 0,0
      @app_details.hide


      @select_app_button = Qt::PushButton.new "Select App..."
      @select_app_button.setEnabled(false)
      @select_app_button.connect(SIGNAL(:released)) { |x|
        @app_list = AppListDialog.new
        @app_list.connect(SIGNAL('accepted()')) {
          $selected_app =  @app_list.app_list.currentItem().app
          @selected_app.setText($selected_app.bundle_name + " (" + $selected_app.bundle_id + ")")
          @uuid.setText($selected_app.uuid)
          begin
            icon_file = $selected_app.get_icon_file
            pixmap = Qt::Pixmap.new(icon_file)
            @icon.setPixmap pixmap.scaledToWidth(50)  unless icon_file.nil?

          rescue => e
            $log.error "Icon CONVERSION failed.  #{e.message}"
            @icon.setPixmap Qt::Pixmap.new
            # lets ignore conversion errors for now..
          end

          @app_details.show
          @app.hide
          emit app_changed()
        }
        @app_list.exec
      }

      @layout.addWidget @select_app_button, 0,1
    end


    def disconnect
      @app.setText("<b>Connect to a device first.</b>")
      @app.show
      @app_details.hide
      @select_app_button.setEnabled(false)
    end

    def enable
      @app.setText("<b><font color='red'>Please click the 'Select Application' button.</font></b>")
      @app.show
      @app_details.hide
      @select_app_button.setEnabled(true)
    end



  end
end