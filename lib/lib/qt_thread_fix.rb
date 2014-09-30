require 'thread'

module Idb
  class QtThreadFix < Qt::Object
      slots 'ruby_thread_timeout()'
      @@ruby_thread_queue  = Queue.new

      def initialize
        super()
        # Enable threading
        @ruby_thread_sleep_period = 0.01
        @ruby_thread_timer = Qt::Timer.new(self)
        connect(@ruby_thread_timer, SIGNAL('timeout()'), SLOT('ruby_thread_timeout()'))
        @ruby_thread_timer.method_missing(:start, 0)
      end

      def ruby_thread_timeout
        unless @@ruby_thread_queue.empty?
          proc_to_call = @@ruby_thread_queue.pop
          proc_to_call.call
        end
        sleep(@ruby_thread_sleep_period)
      end

      def self.ruby_thread_queue
        @@ruby_thread_queue
      end
  end
end