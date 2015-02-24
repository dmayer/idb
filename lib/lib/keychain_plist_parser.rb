# encoding: utf-8
require 'nokogiri'
require 'plist4r'
require 'awesome_print'

module Idb
  class KeychainPlistParser
    attr_accessor :entries

    def initialize data
      $log.info 'Parsing keychain data..'

      begin
        @parsed = JSON.parse(data)
        @entries = Hash.new
        @parsed.each {|x|
          @entries[x[0].to_i] = x[1]
        }
      rescue
        $log.error "Couldn't parse keychain json."
        @entries = {}
      end
    end

  end
end
