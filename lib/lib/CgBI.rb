require 'zlib'

# By Jeff Jarmoc (jeff@jarmoc.com)

# Simplified usage
# ---------------
# require './CGBI.rb'
# CGBI.from_file('./test.png').to_png_file('./outfile.png')

module Idb
  class CGBI
    # http://iphonedevwiki.net/index.php/CgBI_file_format
    PNGHEADER = "\x89PNG\r\n\x1A\n".force_encoding('ASCII-8BIT')

    # Places to hold data
    @cgbi
    @png

    # Places to store header info..
    attr_accessor :width, :height, :depth, :filter

    #Stores the input format
    @orig_format

    def initialize(string)
      unless string[0,8] == PNGHEADER
        raise "Not a PNG"
      end

      if string.match(/CgBI/)
        #puts "Input is CGBI"
        @cgbi = string
        @orig_format = "CGBI"
      else
        #puts "Input is PNG"
        @png = string
        @orig_format = "PNG"
      end
    end

    def self.from_file(file_path)

      self.new(File.open(file_path, 'rb') {|f| f.read})
    end

    def png
      return @png if @png

      all_idats = ""

      #Convert from cgbi, set instance var, return
      data = @cgbi.dup
      png = ""
      png = data.slice!(0,8) #Copy header

      loop do
        # Parse chunks... fixup as needed.
        chunk = {}
        chunk[:length] = data.slice!(0,4).unpack("N")[0]
        chunk[:type] = data.slice!(0,4)

        chunk[:data] = data.slice!(0,chunk[:length] || nil)
        chunk[:crc] = data.slice!(0,4)

        #puts "#{chunk[:length]} : #{chunk[:type]} : #{chunk[:crc].inspect}"

        case chunk[:type]
        when "CgBI"
          #puts "Skipping CgBI Chunk"

        when "IHDR"
          self.width = chunk[:data][0, 4].unpack("L>").first
                self.height = chunk[:data][4, 4].unpack("L>").first
                self.depth = chunk[:data][8, 1].unpack("C").first
                self.filter = chunk[:data][11, 1].unpack("C").first

                #puts "Image: #{width}x#{height} #{depth}bit - Filter: #{filter}"

          png << [chunk[:length]].pack("N")
          png << chunk[:type]
          png << chunk[:data]
          png << chunk[:crc]

        when "IDAT"
          #Inflate the IDAT chunk
          inflate = Zlib::Inflate.new(-15)
          decompressed = inflate.inflate(chunk[:data])

          # Re-order pixels to RGBA
          chunk[:data] = ""
          while (decompressed) do
          #(1..@height).each do |y|
            # Copy over the filter type byte on each line
            # TODO: Might not be necessary for all filter types
            all_idats << decompressed.slice!(0,1)
            (1..@width).each do |x|
              # BGRA => RGBA
              b,g,r,a = decompressed.unpack("CCCC")
              decompressed.slice!(0,4).split(//)

              begin
                all_idats += [r,g,b,a].pack("CCCC")
                decompressed = nil if decompressed.length == 0
              rescue => e
                puts "Left: #{decompressed.inspect}"
                end
            end
          end


        when "IEND"
          raise "Data after IEND" unless data.empty?

          #first write IDAT
          # Deflate the IDAT chunk
          compressed_idats = Zlib::Deflate.deflate(all_idats)
          png << [compressed_idats.length].pack("N")
          png <<  "IDAT"
          png << compressed_idats
          png <<  [Zlib::crc32('IDAT' + compressed_idats)].pack("N")


          png << [chunk[:length]].pack("N")
          png << chunk[:type]
          png << chunk[:data]
          png << chunk[:crc]
          # do stuff
          #puts "#{chunk[:length]} : #{chunk[:type]} : #{chunk[:crc].inspect}"
          break
        else
          # For any chunk we don't modify, copy it through.
          png << [chunk[:length]].pack("N")
          png << chunk[:type]
          png << chunk[:data]
          png << chunk[:crc]
        end
          ######
        #binding.pry
      end

      @png = png
    end

    def to_png_file(file)
      File.open(file, 'w') { |f| f.write(self.png)}
    end

    def cgbi
      return @cgbi

      #TODO: Convert from png, set local var, return
    end

  end


end

