require_relative 'local_storage_tab_widget'
require_relative 'url_handler_widget'
require_relative 'app_binary_tab_widget'
require_relative 'log_widget'
require_relative 'snoop_it_tab_widget'
require_relative 'cycript_console_widget'
require_relative 'pasteboard_monitor_widget'
require 'Qt'

class MainTabWidget < Qt::TabWidget


  def initialize *args
    super *args
    @tabs = Hash.new

    @local_storage = LocalStorageTabWidget.new self
    @local_storage.setEnabled(false)
    @tabs[:local_storage] = addTab(@local_storage, "Local Storage")
    @local_storage.connect(SIGNAL('currentChanged(int)')) { |x|
     @local_storage.currentWidget.refresh
    }

    @url_handler = URLHandlerWidget.new self
    @url_handler.setEnabled(true)
    @tabs[:url_handlers] = addTab(@url_handler, "URL Handlers")
    connect(SIGNAL('currentChanged(int)')) { |x|
#      if isTabEnabled(@tabs[:url_handlers]) and
#          @tabs[:url_handlers] == currentIndex
#
#        @url_handler.refresh
#      end
    }

    @app_binary = AppBinaryTabWidget.new self
    @app_binary.setEnabled(false)
    @tabs[:app_binary] = addTab(@app_binary, "App Binary")
    @app_binary.connect(SIGNAL('currentChanged(int)')) { |x|
      @app_binary.currentWidget.refresh
    }

    @isnoop = SnoopItTabWidget.new self
    @isnoop.setEnabled(true)
    @tabs[:isnoop] = addTab(@isnoop, "Snoop-It")

    @log = LogWidget.new self
    @log.setEnabled(false)
    @tabs[:log] = addTab(@log, "Log View")


    @cycript = CycriptConsoleWidget.new self
    @cycript.setEnabled(true)
    @tabs[:cycript] = addTab(@cycript, "Cycript")

    @pasteboard = PasteboardMonitorWidget.new self
    @pasteboard.setEnabled(true)
    @tabs[:pasteboard] = addTab(@pasteboard, "Pasteboard Monitor")

    disable_all
  end

  def enableLog
    @log.setEnabled(true)
    setTabEnabled(@tabs[:log], true)
  end

  def enableCycript
    @cycript.setEnabled(true)
    setTabEnabled(@tabs[:cycript], true)
  end

  def enableLocalStorage
    @local_storage.setEnabled(true)
    setTabEnabled(@tabs[:local_storage], true)
  end

  def enableURLHandlers
    @url_handler.setEnabled(true)
    setTabEnabled(@tabs[:url_handlers], true)
  end

  def disable_all
    setTabEnabled(@tabs[:local_storage], false)
    setTabEnabled(@tabs[:log], false)
    setTabEnabled(@tabs[:app_binary],false)
#    setTabEnabled(@tabs[:url_handlers],false)
  end

  def clear
    @tabs.each { |tab|
      tab.clear
    }

  end

  def refresh_current_tab
    currentWidget.refresh_current_tab
  end

  def refresh_app_binary
    @app_binary.refresh_current_tab
    @app_binary.setEnabled(true)
  end

  def app_changed
    clear
    enableLocalStorage
    enableURLHandlers
#    refresh_current_tab
    @app_binary.refresh
  end



end