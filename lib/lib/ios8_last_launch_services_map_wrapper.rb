require 'plist4r'

class IOS8LastLaunchServicesMapWrapper

  def initialize plist_file
    @plist_file = plist_file

    @plist_data = Plist4r.open @plist_file
  end


  def data_path_by_bundle_id bundle_id
    @plist_data.to_hash["User"][bundle_id]["Container"]
  end


  def keychain_access_groups_by_bundle_id bundle_id
    @plist_data.to_hash["User"][bundle_id]["keychain-access-groups"]
  end
end