require 'nokogiri'
require 'plist'
require 'awesome_print'

class KeychainPlistParser
  attr_accessor :entries

  def initialize plist_path
    $log.info 'Parsing keychain plist file..'
    @entries = Plist::parse_xml(plist_path)
  end








end