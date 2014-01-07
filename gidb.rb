require 'Qt'
require 'awesome_print'
require_relative 'lib/settings'
require_relative 'lib/simulator'
require_relative 'lib/device'
require_relative 'lib/qt_thread_fix'
require_relative 'gui/app_list_widget_item'
require_relative 'gui/screenshot_wizard'
require_relative 'gui/app_details_group_box'
require_relative 'gui/app_list_dialog'
require_relative 'gui/main_tab_widget'
require_relative 'gui/settings_dialog'
require_relative 'gui/device_info_group_box'
require_relative 'gui/ca_manager_dialog'

TAGET = "Hello"

# logging
require 'log4r'

$width = 1024
$height = 768

class GIDB < Qt::MainWindow

    def initialize
      super


      # initialize log
      $log = Log4r::Logger.new 'gidb'
      outputter = Log4r::Outputter.stdout
      outputter.formatter =  Log4r::PatternFormatter.new(:pattern => "[%l] %d :: %c ::  %m")

      $log.outputters = [ outputter ]



      # enable threading. See https://github.com/ryanmelt/qtbindings/issues/63
      @thread_fix = QtThreadFix.new
      $settings = Settings.new 'config/settings.yml'

      setWindowTitle "gidb"
      Qt::CoreApplication::setApplicationName("gidb")
      setWindowIconText('gidb')
      init_ui
#      size = Qt::Size.new($width, $height)
#      size = size.expandedTo(self.minimumSizeHint())
#      resize(size)
#        resize $width, $height

#      center
       showMaximized();

      show
      self.raise
    end

   def self.execute_in_main_thread(blocking = false, sleep_period = 0.001)
    if Thread.current != Thread.main
      complete = false
      QtThreadFix.ruby_thread_queue << lambda {|| yield; complete = true}
      if blocking
        until complete
          sleep(sleep_period)
        end
      end
    else
      yield
    end
  end

    def init_ui
      # setup central widget and grid layout
      @central_widget = Qt::Widget.new self
      self.setCentralWidget @central_widget
      @grid = Qt::GridLayout.new @central_widget

      @grid.setColumnMinimumWidth(0,450)


      # Box for App details
      @app_details = AppDetailsGroupBox.new @central_widget
      @app_details.connect(SIGNAL(:app_changed)) {
        @main_tabs.app_changed
        @app_binary.app_changed
        @menu_item_screenshot.setEnabled(true)
      }
      @app_details.connect(SIGNAL(:show_device_status)) {
        @device_status = DeviceStatusDialog.new
        @device_status.exec
      }


      @grid.addWidget @app_details, 0,0

      # App Binary Details
      @app_binary = AppBinaryGroupBox.new @central_widget
      @grid.addWidget @app_binary, 1,0
      @app_binary.connect(SIGNAL('binary_analyzed()')) {
        puts "[*] Binary refresh triggered"
        @main_tabs.refresh_app_binary
      }

      @spacer = Qt::SpacerItem.new 0,1, Qt::SizePolicy::Fixed, Qt::SizePolicy::Expanding
      @grid.addItem @spacer, 2,0

      # Main Tab Widget
      @main_tabs = MainTabWidget.new @central_widget
      @grid.addWidget @main_tabs, 0,1,3,1

      # device Details
      @device_details = DeviceInfoGroupBox.new @central_widget
      @grid.addWidget @device_details, 3,0,2,2

      menu

    end


    def menu

      ##########################################
      # MENU
      ##########################################
      # File
      menu_item_settings = Qt::Action.new "&Settings", self
      menu_item_settings.connect(SIGNAL :triggered) {
        setting = SettingsDialog.new self
        setting.exec
      }
      @menu_file = menuBar().addMenu "&File"
      @menu_file.addAction menu_item_settings

      @menu_item_screenshot = Qt::Action.new "&Screenshot", self
      @menu_item_screenshot.setEnabled(false)
      @menu_item_screenshot.connect(SIGNAL :triggered) {
        tool = ScreenShotWizard::ScreenShotWizard.new_with_app $selected_app
      }
      @menu_item_cert = Qt::Action.new "&Certificate Manager", self
      @menu_item_cert.setEnabled(false)
      @menu_item_cert.connect(SIGNAL :triggered) {
        ca = CAManagerDialog.new self
        ca.exec
      }
      @menu_tools = menuBar().addMenu "&Tools"
      @menu_tools.addAction @menu_item_screenshot
      @menu_tools.addAction @menu_item_cert


      #Devices
      @sim_group = Qt::ActionGroup.new @menu_devices

      @menu_devices = menuBar().addMenu "&Devices"
      item = Qt::Action.new "USB Device", self
      item.setCheckable(true)
      item.connect(SIGNAL(:triggered)) { |x|
        $device.disconnect unless $device.nil?

        progress = Qt::ProgressDialog.new "Connecting to device. Please wait...", nil, 0, 2, @central_widget
        progress.setWindowModality(Qt::WindowModal);
        progress.setValue 1
        progress.show
        progress.raise

        begin
          $device = Device.new $settings.ssh_username,
                               $settings.ssh_password,
                               $settings.ssh_host,
                               $settings.ssh_port
        rescue

        end
        if not $device.nil?
          @app_details.enable_select_app
          @device_details.update_device
          @menu_item_cert.setEnabled(true)
          @main_tabs.enableLog

        end

        progress.reset
      }
      menu_item = @menu_devices.addAction item
      @sim_group.addAction item


      x = @menu_devices.addSeparator
      x.setText("Simulators")

      Simulator.get_simulators.each { |s|
        action = @menu_devices.addAction s
        @sim_group.addAction action
        action.setCheckable(true)
        action.connect(SIGNAL(:triggered)) { |x|
          $device = Simulator.new s
          @app_details.enable_select_app
          @device_details.update_device
          @menu_item_cert.setEnabled(true)
        }

        @menu_devices.addAction action
      }




    end


   def center
        qdw = Qt::DesktopWidget.new

        screenWidth = qdw.width
        screenHeight = qdw.height

        x = (screenWidth - $width) / 2
        y = (screenHeight - $height) / 2

        move x, y
    end
end


app = Qt::Application.new ARGV
app.setWindowIcon(Qt::Icon.new 'gui/images/iphone.ico')
app.setApplicationName("gidb")
gidb = GIDB.new

app.exec
$log.info "Performing cleanup before exiting."
$device.close unless $device.nil?
$log.info "Thanks for using gidb."
