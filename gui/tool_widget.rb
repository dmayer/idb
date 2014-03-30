require_relative 'screenshot_wizard'

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
    @spacer = Qt::SpacerItem.new 0,1, Qt::SizePolicy::Fixed, Qt::SizePolicy::Expanding
    layout.addItem @spacer
  end

  def enable_screenshot
    @screen_shot_button.setEnabled(true)

  end

end