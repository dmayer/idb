require 'openssl'
require 'digest/sha1'
require 'sqlite3'


class CAInterface

  # performs uninstall based on sha1 hash provided in certfile
  def remove_cert cert
    der = cert.to_der

    query = %Q|DELETE FROM "tsettings" WHERE sha1 = #{blobify(sha1_from_der der)};|
    begin
      db = SQLite3::Database.new(@db_path)
      db.execute(query)
      db.close
    rescue Exception => e
      raise "[*] Error writing to SQLite database at #{@db_path}: #{e.message}"
      return
    end
    puts "[*] Operation complete"
  end


  def add_cert cert_file
    cert_file = File.expand_path(cert_file)
    if not File.exist? cert_file
      raise "File #{cert_file} does not exist."
    end

    cert = parse_certificate cert_file

    # create plist file
    #TODO might want to use the plist library instead
    tset   = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<array/>\n</plist>\n"
    data   = cert[:cert].to_der

    puts "[*] Inserting certificate into trust store..."

    query = %Q|INSERT INTO "tsettings" VALUES(#{blobify(cert[:fprint])},#{blobify(cert[:subject])},#{blobify(tset)},#{blobify(data)});|
    begin
      db = SQLite3::Database.new(@db_path)
      db.execute(query)
      db.close
    rescue Exception => e
      if e.message.include? "column sha1 is not unique"
        raise "The same certificate is installed already."
      else
        raise "Error writing to SQLite database at #{@db_path}: #{e.message}"
      end
      return
    end
  end

  def get_certs
    query = %Q|SELECT * FROM "tsettings";|
    begin
      db = SQLite3::Database.new(@db_path)
      result = db.execute(query)
      db.close
    rescue Exception => e
      raise "Error reading from SQLite database at #{@db_path}: #{e.message}"
    end
    result.map { |x|
      OpenSSL::X509::Certificate.new(x[3])
    }
  end


  def sha1_from_der der
    Digest::SHA1.digest(der)
  end

  private

  def string_to_hex(s)
    s.unpack('H*')[0]
  end

  def blobify(bin)
    "X'#{string_to_hex bin}'"
  end

  def parse_certificate cert_file
    puts "[*] Reading and converting certificate..."
    # Open and convert certificate
    cert   = OpenSSL::X509::Certificate.new(File.read(cert_file))
    fprint = sha1_from_der cert.to_der
    subj   = cert.subject.to_der
    puts subj.inspect
    # Thanks Andy Schmitz
    #toSkip = (subj[1].ord & 0x80) == 0 ? 2 : ((subj[2].ord & 0x7f) + 2)
    toSkip = 3
    subj   = subj[toSkip..-1]
#    subj = subj.gsub("PortSwigger","PORTSWIGGER")
    #subj = "1\v0\t\x06\x03U\x04\x06\x13\x02US1\v0\t\x06\x03U\x04\b\x13\x02IL1\x100\x0E\x06\x03U\x04\a\x13\aCHICAGO1\x1A0\x18\x06\x03U\x04\n\x13\x11MATASANO SECURITY1\e0\x19\x06\x03U\x04\v\x13\x12PENTESTING MADNESS1\x1F0\x1D\x06\x03U\x04\x03\x13\x16CA.DANIEL.MATASANO.COM"
    puts subj.inspect

    #subj = "1\x140\x12\x06\x03U\x04\x06\x13\vPORTSWIGGER1\x140\x12\x06\x03U\x04\b\x13\vPORTSWIGGER1\x140\x12\x06\x03U\x04\a\x13\vPORTSWIGGER1\x140\x12\x06\x03U\x04\n\x13\vPORTSWIGGER1\x170\x15\x06\x03U\x04\v\x13\x0EPORTSWIGGER CA1\x170\x15\x06\x03U\x04\x03\x13\x0EPORTSWIGGER CA"

    return {:cert => cert, :fprint => fprint, :subject => subj}
  end


  def validate? cert_file
    if not File.exist? cert_file
      puts "File #{cert_file} does not exist."
      return false
    end

    if not File.file? cert_file
      puts "#{cert_file} is not a file."
      return false
    end

    return true
  end
end



