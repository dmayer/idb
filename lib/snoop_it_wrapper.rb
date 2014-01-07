require 'awesome_print'
require 'xmlrpc/client'

class SnoopItWrapper

  def initialize
   connection = Hash.new
   connection[:host] = "127.0.0.1"
   connection[:port] = "12345"
   connection[:path] = "/xmlrpc"
#    connection[:user] = "snoop-it"
#    connection[:password] = "snoop-it"


    @rpc = XMLRPC::Client.new3(connection)
 end

  def fsevents_after start = Time.now
    start_timestamp = start.to_time.to_i
#    result = @rpc.call("filesystemGetAccessListUpdate", {'lastId' => 0})
    @rpc.call("filesystemGetAccessList", {'from' => start_timestamp})
  end

  def fsevents_delete
    exec_rpc do
      @rpc.call("filesystemDeleteAll")
    end

  end

  def fsevents_after_id  id
    exec_rpc do
      @rpc.call("filesystemGetAccessListUpdate", {'lastId' => id})
    end
  end

  def keychain_after_id id
    exec_rpc do
      @rpc.call("keychainGetListUpdate", {'lastId' => id})
    end
  end

  def keychain_details id
    exec_rpc do
      @rpc.call("keychainGetId", {'id' => id})
    end
  end

  def sensitiveapi_after_id id
    exec_rpc do
      @rpc.call("sensitiveAPIGetListUpdate", {'lastId' => id})
    end
  end

  def sensitiveapi_delete
    exec_rpc do
      @rpc.call("sensitiveAPIDeleteAll")
    end
  end

  def exec_rpc
    begin
      yield
    rescue
      raise "Connection lost. Make sure the app under assessment is running on the device."
    end



  end

  def is_alive?
    result = @rpc.call("ping")
    ap result

  end

end
