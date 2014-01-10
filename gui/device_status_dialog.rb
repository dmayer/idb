class DeviceStatusDialog < Qt::Dialog


  def installed_check_mark
    installed_check_mark = Qt::Label.new
    pixmap = Qt::Pixmap.new "gui/images/check.png"
    installed_check_mark.setPixmap pixmap
    installed_check_mark
  end


  def mark_pbwatcher_installed
    @pbwatcher_label.text = @pbwatcher_label.text + "<br>Found: #{$device.pbwatcher_path}"
    @layout.addWidget installed_check_mark, 4, 1
  end

  def mark_dumpdecrypted_installed
    @dumpdecrypted_label.text = @dumpdecrypted_label.text + "<br>Found: #{$device.dumpdecrypted_path}"
    @layout.addWidget installed_check_mark, 3, 1
  end


  def mark_apt_get_installed
    @aptget_label.text = @aptget_label.text + "<br>Found: #{$device.apt_get_path}"
    @layout.addWidget installed_check_mark, 0, 1
  end

  def mark_open_installed
    @open_label.text = @open_label.text + "<br>Found: #{$device.open_path}"
    @layout.addWidget installed_check_mark, 1, 1
  end

  def mark_openurl_installed
    @openurl_label.text = @openurl_label.text +  "<br>Found: #{$device.openurl_path}"
    @layout.addWidget installed_check_mark, 2, 1
  end

  def initialize *args
    super *args
    @layout = Qt::GridLayout.new
    setLayout(@layout)
    setWindowTitle "Device Status"

    @close_button = Qt::PushButton.new "Close"
    @close_button.connect(SIGNAL(:released)) {|x|
      reject()
    }
    #TODO: prevent closing
    @layout.addWidget @close_button, 5, 2


    #######################
    ### APT-GET
    #######################


    @aptget_label = Qt::Label.new "<b>apt-get / aptitude</b><br>(Install additional software packages)"
    @layout.addWidget @aptget_label, 0, 0


    if $device.apt_get_installed?
      mark_apt_get_installed
    else
      @install_aptget = Qt::PushButton.new "Install"
      @install_aptget.connect(SIGNAL(:released)) {
        $device.install_apt_get
        if $device.apt_get_installed?
          @install_aptget.hide
          mark_apt_get_installed
        end
      }
      @layout.addWidget @install_aptget, 0, 1
    end

    #######################
    ### OPEN
    #######################

    @open_label = Qt::Label.new "<b>open</b><br>(Open apps on the device)"
    @layout.addWidget @open_label, 1, 0

    if $device.open_installed?
      mark_open_installed
    else
      @install_open = Qt::PushButton.new "Install"
      @install_open.connect(SIGNAL(:released)) {
        $device.install_open
        if $device.open_installed?
          @install_open.hide
          mark_open_installed
        end
      }
      @layout.addWidget @install_open, 1, 1
    end

    #######################
    ### OPEN URL
    #######################


    @openurl_label = Qt::Label.new "<b>openURL</b><br>(Open URL on the device)"
    @layout.addWidget @openurl_label, 2, 0


    if $device.openurl_installed?
      mark_openurl_installed
    else
#      @install_openurl = Qt::PushButton.new "Install"
#      @install_openurl.connect(SIGNAL(:released)) {
#        $device.install_openurl
#        if $device.open_installed?
#          @install_open.hide
#          mark_open_installed
#        end
#      }
#      @layout.addWidget @install_openurl, 2, 1
    end


    #######################
    ### DUMPDECRYPTED
    #######################

    @dumpdecrypted_label = Qt::Label.new "<b>dumpdecrypted</b><br>(Decrypt app binaries on the device)"
    @layout.addWidget @dumpdecrypted_label, 3, 0

    if $device.dumpdecrypted_installed?
      mark_dumpdecrypted_installed
    else
      @install_dumpdecrypted = Qt::PushButton.new "Install"
      @layout.addWidget @install_dumpdecrypted, 3, 1
    end


    #######################
    ### PBWATCHER
    #######################


    @pbwatcher_label = Qt::Label.new "<b>pbwatcher</b><br>(idb pasteboard monitor helper)"
    @layout.addWidget @pbwatcher_label, 4, 0

    if $device.pbwatcher_installed?
      mark_pbwatcher_installed
    else
      @install_pbwatcher = Qt::PushButton.new "Install"
      @install_pbwatcher.connect(SIGNAL(:released)) {
        $device.install_pbwatcher
        if $device.pbwatcher_installed?
          @install_pbwatcher.hide
          mark_pbwatcher_installed
        end
      }


      @layout.addWidget @install_pbwatcher, 4, 1
    end


    setFixedHeight(sizeHint().height());
  end


end