require_relative 'shared_libraries_widget'


class AppBinaryTabWidget < Qt::TabWidget


  def initialize *args
    super *args

    @tabs = Hash.new

    @shared_libs = SharedLibrariesWidget.new self
    @tabs[:@shared_libs] = addTab(@shared_libs, "Shared Libraries")
  end

  def clear
    @tabs.each { |tab|
      tab.clear
    }
  end

  def refresh_current_tab
    puts "Refreshing current tab in App binary tab"
    currentWidget.refresh
  end

  def refresh
    @shared_libs.refresh
  end
end