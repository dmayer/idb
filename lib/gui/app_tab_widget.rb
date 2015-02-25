module Idb
  class AppTabWidget < Qt::TabWidget
    attr_accessor :app_details, :app_binary
    signals "app_changed()"
    signals "binary_analyzed()"

    def initialize *args
      super *args

      @layout = Qt::GridLayout.new self
      setLayout(@layout)



      @layout.addWidget @select_app_button, 0,0

      # Box for App details
      @app_details = AppDetailsGroupBox.new @central_widget
      @app_details.connect(SIGNAL(:show_device_status)) {
        @device_status = DeviceStatusDialog.new
        @device_status.exec
      }


      @layout.addWidget @app_details, 0,0,2,1

      # Entitlements
      @app_entitlements = AppEntitlementsGroupBox.new @central_widget
      @layout.addWidget @app_entitlements, 2,0, 1, 2

      # App Binary Details
      @app_binary = AppBinaryGroupBox.new @central_widget
      @layout.addWidget @app_binary, 0,1
      @app_binary.connect(SIGNAL('binary_analyzed()')) {
        emit binary_analyzed()
      }

      @spacer_horizontal = Qt::SpacerItem.new 0,1, Qt::SizePolicy::Expanding, Qt::SizePolicy::Fixed
      @layout.addItem @spacer_horizontal, 0, 3

      @spacer = Qt::SpacerItem.new 0,1, Qt::SizePolicy::Fixed, Qt::SizePolicy::Expanding
      @spacer2 = Qt::SpacerItem.new 0,1, Qt::SizePolicy::Fixed, Qt::SizePolicy::Expanding

      @layout.addItem @spacer, 3, 0


    end

    def app_changed
      @app_binary.app_changed
      @app_details.app_changed
      @app_entitlements.clear
      @app_entitlements.app_changed

    end

  end
end
