require_relative 'shared_libraries_widget'
require_relative 'binary_strings_widget'

class AppBinaryTabWidget < Qt::TabWidget


  def initialize *args
    super *args

    @tabs = Hash.new

    @shared_libs = SharedLibrariesWidget.new self
    @tabs[:@shared_libs] = addTab(@shared_libs, "Shared Libraries")

    @strings = BinaryStringsWidget.new self
    @tabs[:strings] = addTab(@strings, "Strings")

  end

  def clear
    @tabs.each { |tab|
      tab.clear
    }
  end

  def refresh_current_tab
    puts "Refreshing current tab in App binary tab"
  end

  def refresh
  end

  def enableTabs
    @shared_libs.setEnabled(true)
    setTabEnabled(@tabs[:@shared_libs],true)
  end
end