require 'plist4r'

class IOS8LastLaunchServicesMapWrapper

  def initialize plist_file
    @plist_file = plist_file

    @plist_data = Plist4r.open @plist_file
  end

  def entitlements_by_bundle_id bundle_id
    begin
      @plist_data.to_hash["User"][bundle_id]["Entitlements"]
    rescue
      $log.error "Could not read entitlements.."
    end
  end


  def data_path_by_bundle_id bundle_id
    @plist_data.to_hash["User"][bundle_id]["Container"]
  end


  def keychain_access_groups_by_bundle_id bundle_id
    begin
      @plist_data.to_hash["User"][bundle_id]["Entitlements"]["keychain-access-groups"]
    rescue
      ""
    end
  end
end