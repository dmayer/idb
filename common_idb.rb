require 'highline/import'
require "highline/system_extensions"
require 'launchy'
require 'pp'

require_relative 'simulator_certificate_installer'
require_relative 'screen_shot_util'
require_relative 'plist_util'


class CommonIDB

  def handle_select_app
    dirs = get_list_of_apps
    return nil if dirs.nil?

    choose do |menu|
      menu.header = "Select which application to use"
      menu.prompt = "Choice:"

      dirs.each { |d|
        id = File.basename d
        app_name = get_appname_from_id id
        menu.choice("#{id} (#{app_name})") {
          say("[*] Using application #{id}.")
          @app = id

          plist_file = get_plist_file(get_plist_file_name(d))
          @plist = PlistUtil.new plist_file

        }
      }
    end
  end


  private

  # returns the name of the plist file for the current app
  def get_plist_file_name d
    plist_file = (@ops.dir_glob "#{d}/","*app/Info.plist").first

    if not @ops.file_exists? plist_file
      puts "[*] Info.plist not found."
      return nil
    end
    puts "[*] Info.plist found at #{plist_file}"
    return plist_file
  end



  def ensure_app_is_selected
    if @app.nil?
      if handle_select_app.nil?
        raise "Error retrieving list of apps."
      end
    end
  end

end