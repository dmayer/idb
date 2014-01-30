require 'nokogiri'
require 'plist4r'
require 'awesome_print'

class KeychainPlistParser
  attr_accessor :entries

  def initialize plist_path
    $log.info 'Parsing keychain plist file..'
    data = File.open(plist_path,"r").read
    data_utf8 = data.encode('utf-8', :invalid => :replace, :undef => :replace, :replace => '_')
    @entries = Plist4r.new( :from_string => data_utf8)["Array"]
  end








end
