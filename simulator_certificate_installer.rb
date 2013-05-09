require 'openssl'
require 'digest/sha1'
require 'sqlite3'
require 'rbkb'

# Adapted from Mike Tracy's ios_sim_ts_insert.rb
class SimulatorCertificateInstaller

  def initialize sim_path
    @sim_path = sim_path
    @store_path = "/Library/Keychains/TrustStore.sqlite3"
    @db_path = @sim_path + @store_path
  end

  # performs uninstall based on sha1 hash provided in certfile
  def uninstall cert_file
    cert_file = File.expand_path(cert_file)

    if not validate? cert_file
      return
    end

    cert = parse_certificate cert_file

    say "[*] Removing exising entry from trust store..."

    query = %Q|DELETE FROM "tsettings" WHERE sha1 = #{blobify(cert[:fprint])};|
    begin
      db = SQLite3::Database.new(@db_path)
      db.execute(query)
      db.close
    rescue Exception => e
      puts "[*] Error writing to SQLite database at #{@db_path}: #{e.message}"
      return
    end
    puts "[*] Operation complete"
  end

  def reinstall cert_file
    uninstall cert_file
    install cert_file
  end

  def install cert_file
    cert_file = File.expand_path(cert_file)

    if not validate? cert_file
      return
    end

    cert = parse_certificate cert_file



    # create plist file
    #TODO might want to use a plist library instead
    tset   = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<array/>\n</plist>\n"
    data   = cert[:cert].to_der

    def blobify(bin)
      "X'#{bin.hexify}'"
    end

    say "[*] Inserting certificate into trust store..."

    query = %Q|INSERT INTO "tsettings" VALUES(#{blobify(cert[:fprint])},#{blobify(cert[:subject])},#{blobify(tset)},#{blobify(data)});|
    begin
      db = SQLite3::Database.new(@db_path)
      db.execute(query)
      db.close
    rescue Exception => e
      puts "[*] Error writing to SQLite database at #{@db_path}: #{e.message}"
      return
    end
    puts "[*] Operation complete"
  end

  private

  def parse_certificate cert_file
    puts "[*] Reading and converting certificate..."
    # Open and convert certificate
    begin
      cert   = OpenSSL::X509::Certificate.new(File.read(cert_file))
    rescue
      puts "[*] Invalid certificate file #{cert_file}"
      return
    end
    fprint = Digest::SHA1.digest(cert.to_der)
    subj   = cert.subject.to_der

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