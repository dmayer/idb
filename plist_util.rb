require 'plist'

class PlistUtil

  attr_accessor :schemas, :binary_name, :bundle_identifier, :plist_data, :plist_file

  def initialize plist_file
    @plist_file = plist_file

    @plutil = Pathname.new("/usr/bin/plutil")
    if(!@plutil.exist?)
      put "plutil not found at #{@plutil}. aborting"
      return nil
    end

    parse_plist_file
    extract_binary_name
    extract_url_handlers
  end


  private
  def parse_plist_file
    puts "[*] Parsing plist file.."

    # Make sure plist file is in xml and not binary
    `#{@plutil.realpath} -convert xml1 "#{@plist_file}"`

    @plist_data = Plist::parse_xml(@plist_file)
  end

  def extract_url_handlers
    @schemas = Array.new

    if @plist_data["CFBundleURLTypes"] != nil
      for type in @plist_data["CFBundleURLTypes"]
        if !type.nil? and !type["CFBundleURLSchemes"].nil?
          @schemas += type["CFBundleURLSchemes"]
        else
          @schemas += ["None"]
        end
      end
    end
  end

  def extract_binary_name
    @binary_name = @plist_data["CFBundleExecutable"]
    @bundle_identifier =  @plist_data["CFBundleIdentifier"]
  end

end