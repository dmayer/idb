module Idb
  class SnoopItUpdateThread < Qt::Object
    signals "new_events(QVariant)"
    attr_accessor :thread

    def initialize *args
      super *args
      STDOUT.sync = true

      @snoop = SnoopItWrapper.new
    end

    def delete_all
      begin
        @snoop.fsevents_delete
      rescue
        puts "Connection lost"
      end
    end

    def stream function
      puts "Starting"
      @id = 0


      puts @id
      t = Qt::Timer.new self
      t.connect(SIGNAL(:timeout)) {
        puts "triggered"
        thread = Thread.new do
          begin
            events = @snoop.send(function, @id)
          rescue
            puts "Connection lost"
            t.stop
            thread.kill
          end
          @id = events.last["id"] unless events.last.nil?
          puts @id
          emit new_events(events.to_variant) unless events.nil?
        end
        thread.join
      }
      t.start(1000)
    end

  end
end
