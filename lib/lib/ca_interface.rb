require 'openssl'
require 'digest/sha1'
require 'sqlite3'
require "webrick"

module Idb
  class CAInterface
    # performs uninstall based on sha1 hash provided in certfile
    def remove_cert(cert)
      der = cert.to_der

      query = %(DELETE FROM "tsettings" WHERE sha1 = #{blobify(sha1_from_der(der))};)
      begin
        db = SQLite3::Database.new(@db_path)
        db.execute(query)
        db.close
      rescue StandardError => e
        raise "[*] Error writing to SQLite database at #{@db_path}: #{e.message}"
      end
    end

    def server_cert(cert_file)
      FileUtils.mkpath "#{$tmp_path}/CAs"
      cert_file_cache = "#{$tmp_path}/CAs/CA.pem"

      FileUtils.copy cert_file, cert_file_cache
      # copy cert file to tmp
      @server_thread = Thread.new do
        @server = WEBrick::HTTPServer.new(Port: $settings['idb_utility_port'])
        @server.mount "/", WEBrick::HTTPServlet::FileHandler, "#{$tmp_path}/CAs/"
        @server.start
      end

      sleep 0.5
      $device.open_url "http://localhost:#{$settings['idb_utility_port']}/CA.pem"
    end

    def stop_cert_server
      @server.stop unless @server.nil?
      @server_thread.terminate unless @server_thread.nil?
    end

    def read_cert(cert_file)
      cert_file = File.expand_path(cert_file)
      raise "File #{cert_file} does not exist." unless File.exist? cert_file

      parse_certificate cert_file
    end

    def add_cert(cert_file)
      cert = read_cert cert_file

      # create plist file
      # TODO might want to use the plist library instead
      tset = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" \
             "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\"" \
             " \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n" \
             "<plist version=\"1.0\">\n<array/>\n</plist>\n"
      data = cert[:cert].to_der

      insert_cert_into_trust_store cert[:fprint], cert[:subject], tset, data
    end

    def insert_cert_into_trust_store(fprint, subject, tset, data)
      puts "[*] Inserting certificate into trust store..."

      query = %|INSERT INTO "tsettings" VALUES(#{blobify(fprint)},
              #{blobify(subject)},#{blobify(tset)},#{blobify(data)});|
      begin
        db = SQLite3::Database.new(@db_path)
        db.execute(query)
        db.close
      rescue StandardError => e
        error = "column sha1 is not unique"
        raise "The certificate is installed already." if e.message.include? error
        raise "Error writing to SQLite database at #{@db_path}: #{e.message}"
      end
    end

    def certs
      query = %(SELECT * FROM "tsettings";)
      begin
        db = SQLite3::Database.new(@db_path)
        result = db.execute(query)
        db.close
      rescue StandardError => e
        raise "Error reading from SQLite database at #{@db_path}: #{e.message}"
      end
      result.map do |x|
        OpenSSL::X509::Certificate.new(x[3])
      end
    end

    def sha1_from_der(der)
      Digest::SHA1.digest(der)
    end

    private

    def string_to_hex(s)
      s.unpack('H*')[0]
    end

    def blobify(bin)
      "X'#{string_to_hex bin}'"
    end

    def parse_certificate(cert_file)
      puts "[*] Reading and converting certificate..."
      # Open and convert certificate
      cert   = OpenSSL::X509::Certificate.new(File.read(cert_file))
      fprint = sha1_from_der cert.to_der
      subj   = cert.subject.to_der
      puts subj.inspect
      # Thanks Andy Schmitz
      # to_skip = (subj[1].ord & 0x80) == 0 ? 2 : ((subj[2].ord & 0x7f) + 2)
      to_skip = 3
      subj = subj[to_skip..-1]
      puts subj.inspect

      { cert: cert, fprint: fprint, subject: subj }
    end

    def validate?(cert_file)
      unless File.exist? cert_file
        puts "File #{cert_file} does not exist."
        return false
      end

      unless File.file? cert_file
        puts "#{cert_file} is not a file."
        return false
      end

      true
    end
  end
end
