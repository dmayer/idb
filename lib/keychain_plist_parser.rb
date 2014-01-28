require 'nokogiri'
require 'plist4r'
require 'awesome_print'

class KeychainPlistParser
  attr_accessor :entries

  def initialize plist_path
    $log.info 'Parsing keychain plist file..'
    @entries = Plist4r.open(plist_path)["Array"]
  end








end
