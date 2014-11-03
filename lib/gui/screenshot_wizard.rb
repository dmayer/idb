require_relative '../lib/screen_shot_util'
require 'Qt'

module Idb
module ScreenShotWizard
  Pages = Hash.new
  wizard = nil


  class ScreenShotWizard < Qt::Wizard
    attr_accessor :app, :screenshot, :result


    def self.new_with_app app
      wiz = self.new
      wiz.app = app
      wiz.screenshot = ScreenShotUtil.new app.data_dir, $device.ops, false
      wiz
    end

    def initialize
      super

      Pages[:intro] = add_page(IntroPage.new)
      Pages[:open_app] = add_page(OpenAppPage.new self)
      Pages[:background_app] = add_page(BackgroundAppPage.new self)
      Pages[:screen_shot_found] = add_page(ScreenShotFoundPage.new self)
      Pages[:no_screen_shot] = add_page(NoScreenShotPage.new self)
      set_window_title("Screenshot Wizard")
      wizard = self
      show
    end
  end


  class IntroPage < Qt::WizardPage
    def initialize
      super

      setTitle("Introduction")
      label = Qt::Label.new("This wizard will guide you through the testing for the iOS backgrounding screenshot vulnerability.")
      label.word_wrap = true
      layout = Qt::VBoxLayout.new do |v|
        v.add_widget(label)
      end
      setLayout(layout)
    end

    def validatePage
      puts "[*] Marking screenshot time"
      #wiz = parentWidget.parentWidget.parentWidget
      wizard.screenshot.mark
      return true
    end
  end

  class OpenAppPage < Qt::WizardPage

    def initialize *args
      super *args

      setTitle("Launch Application")
      label = Qt::Label.new("Launch the application and navigate to a view that contains potentially sensitive data. Or click below to launch the app automatically.")
      label.word_wrap = true

      launch_button = Qt::PushButton.new "Launch app"
      launch_button.connect(SIGNAL :released) { |x|
        wizard.app.launch
      }

      layout = Qt::VBoxLayout.new do |v|
        v.add_widget(label)
        v.add_widget(launch_button)
      end
      setLayout(layout)

    end


  end


  class BackgroundAppPage < Qt::WizardPage

    def initialize *args
      super *args
      setTitle("Background App")

      label = Qt::Label.new("Now Background the app by hitting the home button (XX in the simulator). Then click continue.")
      label.word_wrap = true
      layout = Qt::VBoxLayout.new do |v|
        v.add_widget(label)
      end
      setLayout(layout)
    end

    def validatePage
      puts "[*] Checking for screenshot"
      #wiz = parentWidget.parentWidget.parentWidget
      wizard.result = wizard.screenshot.check
      puts wizard.result
      true
    end

    def nextId
      #wiz = parentWidget.parentWidget.parentWidget
      puts "Determining next id"
      if wizard.result.nil?
        Pages[:no_screen_shot]
      else
        Pages[:screen_shot_found]
      end
    end


  end

  class NoScreenShotPage < Qt::WizardPage
    def initialize *args
      super *args
      setFinalPage(true)
      setTitle("No Screenshot Found")
      label = Qt::Label.new("No new screenshot was detected for this application.")
      label.word_wrap = true
      layout = Qt::VBoxLayout.new do |v|
        v.add_widget(label)
      end
      setLayout(layout)
    end

    def nextId
      -1
    end
  end

  class ScreenShotFoundPage < Qt::WizardPage
    def initialize *args
      super *args
      setFinalPage(true)
    end

    def initializePage *args
      super  *args

      #wiz = parentWidget.parentWidget.parentWidget
      screenshot_file = wizard.app.cache_file wizard.result

      setTitle("Screenshot Found (click to open)")
      screen = Qt::Pixmap.new screenshot_file
      button = Qt::PushButton.new
      button.setFlat(true)
      button.setIcon(Qt::Icon.new(screen))
      button.setIconSize(parentWidget.size)
      button.connect(SIGNAL :released) { |x|
        $device.ops.open screenshot_file
      }
      layout = Qt::VBoxLayout.new do |v|
        v.add_widget(button)
      end
      setLayout(layout)
    end
  end


  def nextId
    -1
  end
end
end
