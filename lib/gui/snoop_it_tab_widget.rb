require_relative 'snoop_it_fs_events_widget'
require_relative 'snoop_it_keychain_widget'
require_relative 'snoop_it_sensitive_api_widget'


module Idb
  class SnoopItTabWidget < Qt::TabWidget

    def initialize *args
      super *args

      @tabs = Hash.new

      @fsevents = SnoopItFSEventsWidget.new self
      @tabs[:fsevents] = addTab(@fsevents, "File System Events")

      @keychain = SnoopItKeychainWidget.new self
      @tabs[:keychain] = addTab(@keychain, "Keychain Access")

      @sensitiveapi = SnooptItSensitiveAPIWidget.new self
      @tabs[:sensitiveapi] = addTab(@sensitiveapi, "Sensitive APIs")
    end



  end
end