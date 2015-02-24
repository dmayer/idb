
require "hexdump"
module Idb
  class KeychainBinaryWidget < Qt::Widget

#    def hexdump(data, start = 0, finish = nil, width = 16)
#      result = ""
#      ascii = ''
#      counter = 0
#      result += '%06x  ' % start
#      data.each_byte do |c|
#        if counter >= start
#          result += '%02x ' % c
#          ascii << (c.between?(32, 126) ? c : ?.)
#          if ascii.length >= width
#            result += ascii + "\n"
#            ascii = ''
#            result += '%06x  ' % (counter + 1)
#          end
#        end
#        throw :done if finish && finish <= counter
#        counter += 1
#      end rescue :done
#      result += '   ' * (width - ascii.length) + ascii + "\n"
#      result
#    end


    def initialize *args
      super *args
      @layout = Qt::GridLayout.new
      setLayout(@layout)

      @vdata_text = Qt::PlainTextEdit.new
      @vdata_text.setReadOnly(true)

      font = Qt::Font.new("Courier")
      @vdata_text.setFont(font)



      @layout.addWidget @vdata_text, 1, 0
    end

    def set_data data
      output = ""
      begin
        Hexdump.dump(data, {:output => output } )
        @vdata_text.appendPlainText output
      rescue Exception => e
        $log.error "Something went wrong with the hexdump: #{e.exception}"
        $log.error "Tried hexdumping: #{data}"
        @vdata_text.appendPlainText "Error dumping data."
      end
    end

    def clear
      @vdata_text.clear
    end


  end
end