require 'openssl'
require 'digest/sha1'
require 'sqlite3'
#require 'rbkb'

class SimulatorCertificateInstaller

  def initialize sim_path
    @sim_path = sim_path
  end

  def install cert_file
    if not File.exist? cert_file
      puts "File #{cert_file} does not exist."
      return
    end

    if not File.file? cert_file
      puts "#{cert_file} is not a file."
    end


    # Adapted from Mike Tracy's ios_sim_ts_insert.rb
    store_path = "/Library/Keychains/TrustStore.sqlite3"
    db_path = @sim_path + store_path

    puts "[*] Reading and converting certificate..."

    cert   = OpenSSL::X509::Certificate.new(File.read(cert_file))
    fprint = Digest::SHA1.digest(cert.to_der)
    subj   = cert.subject.to_der
    tset   = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n<array/>\n</plist>\n"
    data   = cert.to_der

    def blob(bin)
      "X'#{bin.hexify}'"
    end

    puts "[*] Inserting certificate into trust store..."
    query = %Q|INSERT INTO "tsettings" VALUES(#{blob(fprint)},#{blob(subj)},#{blob(tset)},#{blob(data)});|
    db = SQLite3::Database.new(db_path)
    db.execute(query)
    db.close

    puts "Operation complete"
  end


end