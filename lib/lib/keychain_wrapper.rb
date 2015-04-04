module Idb
  class KeychainWrapper
    attr_accessor :entries
    def initialize
      @keychain_editor_path = $device.keychain_editor_path
      @ops = $device.ops
    end

   def parse
     begin
       @parsed = JSON.parse(dump)
       @entries = Hash.new
       @parsed.each {|x|
         @entries[x[0].to_i] = x[1]
       }
     rescue
       $log.error "Couldn't parse keychain json."
       @entries = {}
     end
    end

    def dump
      $log.info "Dumping keychain using keychain_editor..."
      @ops.execute "#{@keychain_editor_path} --action dump"
    end




    def delete_item service, account, agroup
      $log.info "Deleting keychain item for service='#{service}', account='#{account}', agroup='#{agroup}' ..."
      @ops.execute "#{@keychain_editor_path} --action delete --account \"#{account}\" --service \"#{service}\" --agroup \"#{agroup}\""
    end

    def edit_item service, account, agroup, data
      $log.info "Modifying keychain item for service='#{service}', account='#{account}', agroup='#{agroup}'. New data=#{data}"
      @ops.execute "#{@keychain_editor_path} --action edit --account \"#{account}\" --service \"#{service}\" --agroup \"#{agroup}\" --data \"#{data}\""
    end

  end
end