require_relative 'plist_file_widget'
require_relative 'sqlite_widget'
require_relative 'cache_db_widget'

class LocalStorageTabWidget < Qt::TabWidget

  def initialize *args
    super *args

    @tabs = Hash.new

    @plist = PlistFileWidget.new self
    @tabs[:plist] = addTab(@plist, "plists")

    @sqlite = SqliteWidget.new self
    @tabs[:sqlite] = addTab(@sqlite, "sqlite dbs")

    @cachedb = CacheDbWidget.new self
    @tabs[:cachedb] = addTab(@cachedb, "Cache.dbs")

  end

  def clear
    @tabs.each { |tab|
      tab.clear
    }
  end

  def refresh_current_tab
    puts "refresh local storage tab"
    currentWidget.refresh
  end


end