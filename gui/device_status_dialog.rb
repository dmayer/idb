class DeviceStatusDialog < Qt::Dialog

  def initialize *args
    super *args
    @layout = Qt::GridLayout.new
    setLayout(@layout)
    setWindowTitle "Device Status"

    @close_button = Qt::PushButton.new "Close"
    @close_button.connect(SIGNAL(:released)) {|x|
      reject()
    }
    @layout.addWidget @close_button, 4, 2

    @aptget_label = Qt::Label.new "<b>apt-get</b><br>(Install additional software packages)"
    @layout.addWidget @aptget_label, 0, 0

    if $device.apt_get_installed?
      @aptget_installed = Qt::Label.new
      pixmap = Qt::Pixmap.new "gui/images/check.png"
      @aptget_installed.setPixmap pixmap
      @layout.addWidget @aptget_installed, 0, 1
    else
      @install_aptget = Qt::PushButton.new "Install"
      @install_aptget.connect(SIGNAL(:released)) {
        $device.install_apt_get
      }
      @layout.addWidget @install_aptget, 0, 1
    end

    @open_label = Qt::Label.new "<b>open</b><br>(Open apps on the device)"
    @layout.addWidget @open_label, 1, 0

    if $device.open_installed?
      @open_installed = Qt::Label.new
      pixmap = Qt::Pixmap.new "gui/images/check.png"
      @open_installed.setPixmap pixmap
      @layout.addWidget @open_installed, 1, 1
    else
      @install_open = Qt::PushButton.new "Install"
      @install_open.connect(SIGNAL(:released)) {
        $device.install_open
      }
      @layout.addWidget @install_open, 1, 1
    end

    openurl_label = "<b>openURL</b><br>(Open URL on the device)"
    if $device.openurl_installed?
      @openurl_label = Qt::Label.new  "#{openurl_label}<br>Found: #{$device.openurl_path}"
      @layout.addWidget @openurl_label, 2, 0
      @openurl_installed = Qt::Label.new
      pixmap = Qt::Pixmap.new "gui/images/check.png"
      @openurl_installed.setPixmap pixmap
      @layout.addWidget @openurl_installed, 2, 1
    else
      @openurl_label = Qt::Label.new openurl_label
      @layout.addWidget @openurl_label, 2, 0
      @install_openurl = Qt::PushButton.new "Install"
      @layout.addWidget @install_openurl, 2, 1
    end



    @dumpdecrypted_label = Qt::Label.new "<b>dumpdecrypted</b><br>(Decrypt app binaries on the device)"
    @layout.addWidget @dumpdecrypted_label, 3, 0

    if $device.dumpdecrypted_installed?
      @dumpdecrypted_installed = Qt::Label.new
      pixmap = Qt::Pixmap.new "gui/images/check.png"
      @dumpdecrypted_installed.setPixmap pixmap
      @layout.addWidget @dumpdecrypted_installed, 3, 1
    else
      @install_dumpdecrypted = Qt::PushButton.new "Install"
      @layout.addWidget @install_dumpdecrypted, 3, 1
    end

    setFixedHeight(sizeHint().height());
  end


end