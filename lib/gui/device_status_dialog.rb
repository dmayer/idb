module Idb
  class DeviceStatusDialog < Qt::Dialog


    def installed_check_mark
      installed_check_mark = Qt::Label.new
      pixmap = Qt::Pixmap.new File.join(File.dirname(File.expand_path(__FILE__)), '/images/check.png')
      installed_check_mark.setPixmap pixmap
      installed_check_mark
    end

    def mark_rsync_installed
      @rsync_label.text = @rsync_label.text + "<br>found: #{$device.rsync_path}"
      @layout.addWidget installed_check_mark, 7, 1
      setFixedHeight(sizeHint().height());
    end

    def mark_keychain_editor_installed
      @keychain_editor_label.text = @keychain_editor_label.text + "<br>found: #{$device.keychain_editor_path}"
      @layout.addWidget installed_check_mark, 6, 1
      setFixedHeight(sizeHint().height());
    end

    def mark_pcviewer_installed
      @pcviewer_label.text = @pcviewer_label.text + "<br>found: #{$device.pcviewer_path}"
      @layout.addWidget installed_check_mark, 5, 1
      setFixedHeight(sizeHint().height());
    end

    def mark_pbwatcher_installed
      @pbwatcher_label.text = @pbwatcher_label.text + "<br>found: #{$device.pbwatcher_path}"
      @layout.addWidget installed_check_mark, 4, 1
      setFixedHeight(sizeHint().height());
    end

    def mark_dumpdecrypted_installed
      @dumpdecrypted_label.text = @dumpdecrypted_label.text + "<br>Found: #{$device.dumpdecrypted_path}"
      @layout.addWidget installed_check_mark, 3, 1
      setFixedHeight(sizeHint().height());
    end


    def mark_apt_get_installed
      @aptget_label.text = @aptget_label.text + "<br>Found: #{$device.apt_get_path}"
      @layout.addWidget installed_check_mark, 0, 1
      setFixedHeight(sizeHint().height());
    end

    def mark_open_installed
      @open_label.text = @open_label.text + "<br>Found: #{$device.open_path}"
      @layout.addWidget installed_check_mark, 1, 1
      setFixedHeight(sizeHint().height());
    end

    def mark_openurl_installed
      @openurl_label.text = @openurl_label.text +  "<br>Found: #{$device.openurl_path}"
      @layout.addWidget installed_check_mark, 2, 1
      setFixedHeight(sizeHint().height());
    end

    def mark_cycript_installed
      @cycript_label.text = @cycript_label.text +  "<br>Found: #{$device.cycript_path}"
      @layout.addWidget installed_check_mark, 8, 1
      setFixedHeight(sizeHint().height());
    end


    def apt_get_section
      @aptget_label = Qt::Label.new "<b>apt-get / aptitude</b><br>(Install additional software packages)"
      @layout.addWidget @aptget_label, 0, 0


      if $device.apt_get_installed?
        mark_apt_get_installed
      else
        @install_aptget = Qt::PushButton.new "Install"
        @install_aptget.connect(SIGNAL(:released)) {
          error = Qt::MessageBox.new
          error.setText("Aptitude or apt-get must be installed on the device using Cydia.")
          error.setIcon(Qt::MessageBox::Critical)
          error.exec
          if $device.apt_get_installed?
            @install_aptget.hide
            mark_apt_get_installed
          end
        }
        @layout.addWidget @install_aptget, 0, 1
      end

    end

    def open_section
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
          else
            error = Qt::MessageBox.new
            error.setInformativeText("open could not be installed. Please make sure Cydia has finished all tasks and is closed on the device.")
            error.setIcon(Qt::MessageBox::Critical)
            error.exec
          end
        }
        @layout.addWidget @install_open, 1, 1
      end

    end

    def open_url_section
      @openurl_label = Qt::Label.new "<b>openURL</b><br>(Open URL on the device)"
      @layout.addWidget @openurl_label, 2, 0


      if $device.openurl_installed?
        mark_openurl_installed
      else
      end

    end

    def dumpdecrypted_section
      @dumpdecrypted_label = Qt::Label.new "<b>dumpdecrypted</b><br>(Decrypt app binaries on the device).<br>Developed and maintained by Stefan Esser https://github.com/stefanesser/dumpdecrypted"
      @layout.addWidget @dumpdecrypted_label, 3, 0

      if $device.dumpdecrypted_installed?
        mark_dumpdecrypted_installed
      else
        @install_dumpdecrypted = Qt::PushButton.new "Install"
        @install_dumpdecrypted.connect(SIGNAL(:released)) {
          $device.install_dumpdecrypted
          if $device.dumpdecrypted_installed?
            @install_dumpdecrypted.hide
            mark_dumpdecrypted_installed
          else
            error = Qt::MessageBox.new
            error.setInformativeText("No compiled version of dumpdecrypted was found in utils/dumpdecrypted. It cannot be shipped with idb due to licensing issues. Compilation failed likely due to XCode 5 not shipping the right version of gcc anymore. Try manually copying dumpdecrypted.dylib into /var/root on the device.")
            error.setIcon(Qt::MessageBox::Critical)
            error.exec
          end

        }
        @layout.addWidget @install_dumpdecrypted, 3, 1
      end
    end


    def pbwatcher_section
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

    end

    def pcviewer_section
      @pcviewer_label = Qt::Label.new "<b>pcviewer</b><br>(idb file protection class helper)"
      @layout.addWidget @pcviewer_label, 5, 0

      if $device.pcviewer_installed?
        mark_pcviewer_installed
      else
        @install_pcviewer = Qt::PushButton.new "Install"
        @install_pcviewer.connect(SIGNAL(:released)) {
          $device.install_pcviewer
          if $device.pcviewer_installed?
            @install_pcviewer.hide
            mark_pcviewer_installed
          end
        }


        @layout.addWidget @install_pcviewer, 5, 1
      end

    end

    def keychaineditor_section
      @keychain_editor_label = Qt::Label.new "<b>keychain_editor</b><br>(provides keychain edit functionality.<br>by Nitin Jami)"
      @layout.addWidget @keychain_editor_label, 6, 0

      if $device.keychain_editor_installed?
        mark_keychain_editor_installed
      else
        @install_keychain_editor = Qt::PushButton.new "Install"
        @install_keychain_editor.connect(SIGNAL(:released)) {
          $device.install_keychain_editor
          if $device.keychain_editor_installed?
            @install_keychain_editor.hide
            mark_keychain_editor_installed
          end
        }


        @layout.addWidget @install_keychain_editor, 6, 1

      end
    end

    def rsync_section
      @rsync_label = Qt::Label.new "<b>rsync</b><br>(folder synchronization)"
      @layout.addWidget @rsync_label, 7, 0

      if $device.rsync_installed?
        mark_rsync_installed
      else
        @install_rsync = Qt::PushButton.new "Install"
        @install_rsync.connect(SIGNAL(:released)) {
          $device.install_rsync
          if $device.rsync_installed?
            @install_rsync.hide
            mark_rsync_installed
          else
            error = Qt::MessageBox.new
            error.setInformativeText("rsync could not be installed. Please make sure Cydia has finished all tasks and is closed on the device.")
            error.setIcon(Qt::MessageBox::Critical)
            error.exec
          end
        }


        @layout.addWidget @install_rsync, 7, 1

      end
    end

    def cycript_section
      @cycript_label = Qt::Label.new "<b>cycript</b><br>(explore and modify running applications using a hybrid of Objective-C++ and JavaScript. http://www.cycript.org/ )"
      @layout.addWidget @cycript_label, 8, 0

      if $device.cycript_installed?
        mark_cycript_installed
      else
        @install_cycript = Qt::PushButton.new "Install"
        @install_cycript.connect(SIGNAL(:released)) {
          $device.install_cycript
          if $device.cycript_installed?
            @install_cycript.hide
            mark_cycript_installed
          else
            error = Qt::MessageBox.new
            error.setInformativeText("cycript could not be installed. Please make sure Cydia has finished all tasks and is closed on the device.")
            error.setIcon(Qt::MessageBox::Critical)
            error.exec
          end
        }
        @layout.addWidget @install_cycript, 8, 1
      end
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
      @layout.addWidget @close_button, 10, 2

      apt_get_section
      open_section
      open_url_section
      dumpdecrypted_section
      pbwatcher_section
      pcviewer_section
      keychaineditor_section
      rsync_section
      cycript_section


      setFixedHeight(sizeHint().height());
    end


    end
  end
