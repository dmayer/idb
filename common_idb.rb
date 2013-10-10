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
      menu.header = 'Select which application to use'
      menu.prompt = 'Choice:'

      dirs.each { |d|
        id = File.basename d
        app_name = get_appname_from_id id
        menu.choice("#{id} (#{app_name})") {
          say("[*] Using application #{id}.")
          @app = id
          @app_dir = d
          $prompt = "idb [#{id}] > "
          FileUtils.mkdir_p "tmp/#{id}"

          plist_file = get_plist_file(get_plist_file_name(d))
          @plist = PlistUtil.new plist_file
          @plist.parse_info_plist

        }
      }
    end
  end

  def handle_app line
    tokens = line.split(' ')

    if tokens.length < 2
      puts "app <option> where <option> is one of:"
      puts

      puts "Non-App Specific"
      puts "----------------"
      puts "list         - Lists all installed apps."
      puts "select       - Selects an app for other operations."
      puts

      puts "App Specific"
      puts "------------"
      puts "archive      - Download application bundle as .tar.gz."
      puts "bundleid     - Print bundle id."
      puts "decrypt      - Decrypts and downloads application binary."
      puts "download     - Downloads application binary."
      puts "get_plists   - List, view, and download any .plist files."
      puts "get_sqlite   - List, view, and download any .sqlite files."
      puts "get_cachedb  - List and download any Cache.db files."
      puts "info_plist   - View or download Info.plist."
      puts "launch       - Start the application."
      puts "name         - Print app name"
      puts "url_handlers - Lists URL handleres registered by app."
      return
    end

    case tokens[1]
      when "select"
        handle_select_app
      when "list"
        app_list
      when "download"
        app_download
      when "decrypt"
        app_decrypt
      when "url_handlers"
        app_url_handlers
      when "archive"
        app_archive
      when "get_plists"
        app_get_plists
      when "get_sqlite"
        app_get_sqlite
      when "get_cachedb"
        app_get_cachedb
      when "info_plist"
        app_info_plist
      when "launch"
        app_launch
      when "bundleid"
        ensure_app_is_selected
        puts "Bundle identifier for #{@app}:"
        puts @plist.bundle_identifier

      when "name"
        ensure_app_is_selected
        puts "Bianry name for #{@app}:"
        puts @plist.binary_name
    end
  end

  private

  def app_info_plist
    ensure_app_is_selected

    plist_file = get_plist_file(get_plist_file_name(@app_dir))
    local_path = "tmp/#{@app}/Info.plist"
    @ops.download plist_file, local_path

    choose do |menu|
      menu.header = 'What would you like to do?'
      menu.choice("Download Info.plist") {
        say("[*] File downloaded to #{local_path}.")
      }
      menu.choice("Display Info.plist") {
        say("[*] Listing  #{plist_file}.")
        PlistUtil.new(local_path).dump
      }
      menu.choice("Open Info.plist in external editor (if associated)") {
        Launchy.open local_path
      }
    end
  end




  def app_get_cachedb
    ensure_app_is_selected

    puts "[*] Looking for Cache.db files..."
    cachedb_files = @ops.dir_glob(@app_dir, "**/Cache.db")
    loop do
      choose do |menu|
        menu.header = 'Select Cache.db file:'
        menu.prompt = "Choice (or 'quit'):"

        cachedb_files.each {|f|
          relative_file = f.sub(@app_dir,'')
          menu.choice("#{relative_file}") {

            local_path = "tmp/#{@app}/#{File.basename f}"
            if @ops.download f, local_path
              choose do |menu|
                menu.header = 'What would you like to do?'
                menu.choice("Download") {
                  say("[*] File downloaded to #{local_path}.")
                }
                menu.choice("Open in sqlite command line tool") {
                  system("sqlite3 #{local_path}")
                }
              end
            end
          }
        }
        menu.choice(:quit) { return }
      end
    end
  end

  def app_get_sqlite
    ensure_app_is_selected

    puts "[*] Looking for sqlite files..."
    plist_files = @ops.dir_glob(@app_dir, "**/*sqlite")

    loop do
      choose do |menu|
        menu.header = 'Select sqlite file:'
        menu.prompt = "Choice (or 'quit'):"

        plist_files.each {|f|
          relative_file = f.sub(@app_dir,'')
          menu.choice("#{relative_file}") {

            local_path = "tmp/#{@app}/#{File.basename f}"
            if @ops.download f, local_path
              choose do |menu|
                menu.header = 'What would you like to do?'
                menu.choice("Download") {
                  say("[*] File downloaded to #{local_path}.")
                }
                menu.choice("Open in sqlite command line tool") {
                  system("sqlite3 #{local_path}")
                }
                menu.choice("Open in external editor (if associated)") {
                  Launchy.open local_path
                }
              end
            end
          }
        }
        menu.choice(:quit) { return }
      end
    end
  end


  def app_get_plists
    ensure_app_is_selected

    puts "[*] Looking for plist files..."
    plist_files =  @ops.dir_glob(@app_dir, "**/*plist")

    loop do
      choose do |menu|
        menu.header = 'Select plist file:'
        menu.prompt = "Choice (or 'quit'):"

        plist_files.each {|f|

          relative_file = f.sub(@app_dir,'')
          menu.choice("#{relative_file}") {

            local_path = "tmp/#{@app}/#{File.basename f}"
            if @ops.download f, local_path
              choose do |menu|
                menu.header = 'What would you like to do?'
                menu.choice("Display") {
                  say("[*] Listing  #{relative_file}.")
                  PlistUtil.new(local_path).dump
                }
                menu.choice("Open in external editor (if associated)") {
                  Launchy.open local_path
                }
              end
            end
          }
        }
        menu.choice("[Download all] ") {
          plist_files.each { |f|
            next unless @ops.file? f

            relative_file = f.sub(@app_dir,'')
            puts "Downloading #{relative_file}"

            local_path = "tmp/#{@app}/#{relative_file}"
            FileUtils.mkdir_p(File.dirname(local_path))
            @ops.download f, local_path
          }
        }
        menu.choice(:quit) { return }
      end
    end
  end

  def app_archive
    ensure_app_is_selected
    puts "[*] Creating tar.gz of #{@app_dir}. This may take a while..."
    local_path = "tmp/#{@app}/app_archive.tar.gz"


    @ops.execute "/usr/bin/tar cfz \"#{local_path}\" \"#{@app_dir}\""

    puts "[*] App archive downloaded to #{local_path}."
  end

  def app_url_handlers
    ensure_app_is_selected
    puts "[*] Registered URL schemas based on Info.plist:"
    if @plist.schemas.empty?
      puts "No URL schemas found."
    end
    puts @plist.schemas
  end

  def path_to_app_binary
    puts "[*] Locating application binary..."
    dirs = @ops.dir_glob("#{@app_dir}/","**")
    dirs.select! { |f|
      @ops.file_exists? "#{f}/#{@plist.binary_name}"
    }

    "#{dirs.first}/#{@plist.binary_name}"
  end


  def app_download
    ensure_app_is_selected

    full_remote_path = path_to_app_binary
    puts "[*] Downloading binary #{full_remote_path}"
    local_path = "tmp/#{@app}/#{@plist.binary_name}.app"
    @ops.download full_remote_path, local_path

    puts "[*] Binary downloaded to #{local_path}"
  end


  def app_list
    dirs = get_list_of_apps
    apps = dirs.map { |x|
      id = File.basename x
      app_name = get_appname_from_id id
      "#{id} (#{app_name})"
    }

    h = HighLine.new
    puts h.list apps

  end

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