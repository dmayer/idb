require_relative 'local_storage_tab_widget'
require_relative 'url_handler_widget'
require_relative 'app_binary_tab_widget'
require_relative 'log_widget'
require_relative 'snoop_it_tab_widget'
require_relative 'cycript_console_widget'
require_relative 'pasteboard_monitor_widget'
require_relative 'fs_viewer_tab_widget'
require_relative 'key_chain_widget'
require 'Qt'

class MainTabWidget < Qt::TabWidget


  def initialize *args
    super *args
    @tabs = Hash.new

    @local_storage = LocalStorageTabWidget.new self
    @local_storage.setEnabled(false)
    @tabs[:local_storage] = addTab(@local_storage, "Storage")
    @local_storage.connect(SIGNAL('currentChanged(int)')) { |x|
     #@local_storage.currentWidget.refresh
    }

    @url_handler = URLHandlerWidget.new self
    @url_handler.setEnabled(false)
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
    @tabs[:app_binary] = addTab(@app_binary, "Binary")
    @app_binary.connect(SIGNAL('currentChanged(int)')) { |x|
      @app_binary.currentWidget.refresh
    }

    @fs_viewer = FsViewerTabWidget.new self
    @fs_viewer.setEnabled(false)
    @tabs[:fs_viewer] = addTab(@fs_viewer, "Filesystem")

    @isnoop = SnoopItTabWidget.new self
    @isnoop.setEnabled(false)
    @tabs[:isnoop] = addTab(@isnoop, "Snoop-It")

    @log = LogWidget.new self
    @log.setEnabled(false)
    @tabs[:log] = addTab(@log, "Log")

    @keychain = KeyChainWidget.new self
    @keychain.setEnabled(false)
    @tabs[:keychain] = addTab(@keychain, "Keychain")

    @cycript = CycriptConsoleWidget.new self
    @cycript.setEnabled(false)
    @tabs[:cycript] = addTab(@cycript, "Cycript")

    @pasteboard = PasteboardMonitorWidget.new self
    @pasteboard.setEnabled(false)
    @tabs[:pasteboard] = addTab(@pasteboard, "Pasteboard")

    disable_all
  end

  def enableLog
    @log.setEnabled(true)
    setTabEnabled(@tabs[:log], true)
  end

  def enableAppBinary
    @app_binary.setEnabled(true)
    setTabEnabled(@tabs[:app_binary], true)
    @app_binary.enableTabs
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

  def enablePasteboard
    @pasteboard.setEnabled(true)
    setTabEnabled(@tabs[:pasteboard], true)
  end

  def enableFSViewer
    @fs_viewer.setEnabled(true)
    setTabEnabled(@tabs[:fs_viewer], true)
  end

  def enableKeychain
    @keychain.setEnabled(true)
    setTabEnabled(@tabs[:keychain], true)
  end


  def enableDeviceFunctions
    enableCycript
    enableLog
    enablePasteboard
    enableKeychain
  end

  def disable_all
    setTabEnabled(@tabs[:local_storage], false)
    setTabEnabled(@tabs[:log], false)
    setTabEnabled(@tabs[:app_binary],false)
    setTabEnabled(@tabs[:url_handlers],false)
    setTabEnabled(@tabs[:pasteboard],false)
    setTabEnabled(@tabs[:cycript],false)
    setTabEnabled(@tabs[:isnoop],false)
    setTabEnabled(@tabs[:fs_viewer],false)
    setTabEnabled(@tabs[:keychain],false)
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
    enableAppBinary
  end

  def app_changed
    clear
    enableLocalStorage
    enableURLHandlers
#    refresh_current_tab
    @app_binary.refresh
    enableFSViewer
    @fs_viewer.set_start  $selected_app.app_dir

  end



end