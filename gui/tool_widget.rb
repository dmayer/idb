require_relative 'screenshot_wizard'
require_relative '../lib/host_file_wrapper'

class ToolWidget < Qt::Widget

  def initialize *args
    super *args

    layout = Qt::VBoxLayout.new
    setLayout(layout)


    @screen_shot_box = Qt::GroupBox.new "Screenshot Tool"
    @screen_shot_description = Qt::Label.new "iOS takes an automatic screenshot whenever an app is placed into the background. This Wizard walks you through the steps that are required verify that the assessed app properly protects sensitive data before backgrounding."
    @screen_shot_description.setWordWrap true

    @screen_shot_button = Qt::PushButton.new "Check for Automatic Background Screenshot"
    @screen_shot_button.connect(SIGNAL :released) {
      tool = ScreenShotWizard::ScreenShotWizard.new_with_app $selected_app
    }

    screen_shot_layout = Qt::GridLayout.new
    @screen_shot_box.setLayout(screen_shot_layout)
    screen_shot_layout.addWidget @screen_shot_description, 0, 0
    screen_shot_layout.addWidget @screen_shot_button, 1, 0

    layout.addWidget @screen_shot_box


    @cert_box = Qt::GroupBox.new "Certificate Manager"
    @cert_description = Qt::Label.new "This tool allows you to manage SSL CA certificates both on iOS devices and the iOS simulator. For devices, the certificates are installed via Safari and a private web server run by idb. For the simulator they are directly stored in the simulator's truststore. Please report any problems with either system on github."
    @cert_description.setWordWrap true

    @cert_button = Qt::PushButton.new "Launch Certificate Manager"
    @cert_button.connect(SIGNAL :released) {
      ca = CAManagerDialog.new self
      ca.exec
    }

    @burp_description = Qt::Label.new "Running the iDevice through burp? Click below to install the Portswigger CA certificate on the device by opening the  http://burp/cert URL handler."
    @burp_description.setWordWrap true
    @burp_button = Qt::PushButton.new "Install Burp Cert"
    @burp_button.connect(SIGNAL :released) {
      $device.open_url "http://burp/cert"
    }

    cert_layout = Qt::GridLayout.new
    @cert_box.setLayout(cert_layout)
    cert_layout.addWidget @cert_description, 0, 0, 1, 2
    cert_layout.addWidget @cert_button, 1, 0
    cert_layout.addWidget @burp_button, 1, 1

    layout.addWidget @cert_box


    @host_editor_box = Qt::GroupBox.new "/etc/hosts File Editor"

    @host_file_text = Qt::PlainTextEdit.new
    @host_wrapper = HostFileWrapper.new

    @host_editor_save_button = Qt::PushButton.new "Save"
    @host_editor_save_button.connect(SIGNAL :released) {
      @host_wrapper.save @host_file_text.plainText
    }

    @host_editor_reset_button = Qt::PushButton.new "Load"
    @host_editor_reset_button.connect(SIGNAL :released) {
      @host_file_text.clear
      @host_file_text.appendPlainText @host_wrapper.content
    }

    host_editor_layout = Qt::GridLayout.new
    @host_editor_box.setLayout(host_editor_layout)
    host_editor_layout.addWidget @host_file_text, 0, 0, 1, 2
    host_editor_layout.addWidget @host_editor_reset_button, 1, 0
    host_editor_layout.addWidget @host_editor_save_button, 1, 1

    layout.addWidget @host_editor_box




    @spacer = Qt::SpacerItem.new 0,1, Qt::SizePolicy::Fixed, Qt::SizePolicy::Expanding
    layout.addItem @spacer
  end

  def enable_screenshot
    @screen_shot_button.setEnabled(true)

  end

end