require 'plist4r'
require 'sqlite3'

class IOS10ApplicationStateDbWrapper
  def initialize
    @db_file = "/User/Library/FrontBoard/applicationState.db"

    @cache_path = "#{$tmp_path}/device/applicationState.db"

    @ldid_binary = "/usr/bin/ldid"



    # download latest db file
    FileUtils.mkpath "#{$tmp_path}/device" unless File.directory? "#{$tmp_path}/device"
    $device.ops.download @db_file, @cache_path

  end


  def entitlements_by_binary(binary_path)
    unless $device.ops.file_exists?(@ldid_binary)
      $log.error "Cannot find ldid binary at #{@ldid_binary}"
      return ""
    end

    plist = $device.ops.execute("#{@ldid_binary} -e '#{binary_path}'")
    entitlements = Plist4r.new({:from_string => plist})
    puts entitlements
    entitlements
  end


  def data_path_by_bundle_id(bundle_id)

    #puts @cache_path
    db = SQLite3::Database.open @cache_path
    #puts db.inspect

    #puts bundle_id
    plist = ""

    # I fail to get prepared statements to work with SQLite... So using strig concatenation instead. here be dragons
    stmnt = db.prepare "SELECT kvs.value FROM application_identifier_tab left join kvs on application_identifier_tab.id = kvs.application_identifier where kvs.key = 2 and application_identifier_tab.application_identifier='#{bundle_id}'"
    # stmnt.bind_params(bundle_id)
    rs = stmnt.execute
    #
    #binding.pry
    #puts rs.inspect
    row = rs.next
    if row.nil?
      return nil
    end
    #puts row.inspect
    plist = row[0]

    #puts plist

    outer_plist = Plist4r.new({:from_string => plist})
    h = outer_plist.to_hash
    if h.key? "sandboxPath"
      return h["sandboxPath"]
    end
    #puts outer_plist.inspect
    plist = outer_plist.to_hash["String"]
    inner_plist = Plist4r::Plist.new({:from_string => plist})
    return inner_plist.to_hash["$objects"][4]

  end

  def keychain_access_groups_by_binary binary_path
    unless $device.ops.file_exists?(@ldid_binary)
      $log.error "Cannot find ldid binary at #{@ldid_binary}"
      return ""
    end

    plist = $device.ops.execute("#{@ldid_binary} -e '#{binary_path}'")
    entitlements = Plist4r.new({:from_string => plist})
    puts entitlements["keychain-access-groups"]
    return entitlements["keychain-access-groups"]
  end
end
