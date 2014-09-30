require_relative '../lib/snoop_it_wrapper'

module Idb
  class SnooptItSensitiveAPIWidget < Qt::Widget


    def initialize *args
      super *args

      @snoop = SnoopItWrapper.new

      @model = Qt::StandardItemModel.new

      @selection_model = Qt::ItemSelectionModel.new @model
      @selection_model.model

      @events_tab = Qt::TableView.new
      @events_tab.setModel @selection_model.model
      @events_tab.setSelectionModel(@selection_model)

      @events_tab.setSelectionBehavior(Qt::AbstractItemView::SelectRows)
      @events_tab.setEditTriggers(Qt::AbstractItemView::NoEditTriggers	)

      @start = Qt::PushButton.new "Start"
      @start.connect(SIGNAL :released) {
        @start.setEnabled(false)
        @stop.setEnabled(true)
        start_stream
      }

      @stop = Qt::PushButton.new "Stop"
      @stop.setEnabled(false)
      @stop.connect(SIGNAL :released) {
        @start.setEnabled(true)
        @stop.setEnabled(false)
        stop_stream
      }


      layout = Qt::VBoxLayout.new do |v|
        v.add_widget(@events_tab)
        v.add_widget(@start)
        v.add_widget(@stop)
      end
      setLayout(layout)



    end

    def reset
      @model.clear
      @model.setHorizontalHeaderItem(0, Qt::StandardItem.new("Subject"))
      @model.setHorizontalHeaderItem(1, Qt::StandardItem.new("Expiry"))
      @model.setHorizontalHeaderItem(2, Qt::StandardItem.new("Issuer"))

    end

    def start_stream


      @thread = SnoopItUpdateThread.new
      @thread.connect(SIGNAL('new_events(QVariant)')) { |events|
        if not events.value.nil?
          @events_tab.blockSignals(true)
          events.value.each { |e|
            #TODO if there are many, display status
            row = parse_event e
            @model.appendRow(row)
            Qt::Application::processEvents

          }
          @events_tab.blockSignals(false)
          @events_tab.resizeColumnsToContents
          @events_tab.resizeRowsToContents
        end
      }
      @snoop.sensitiveapi_delete
      @thread.stream 'sensitiveapi_after_id'

    end


    private
    def parse_event e
      row = Array.new
      row <<   Qt::StandardItem.new(e.value["id"].value.to_s)

      row <<   Qt::StandardItem.new(Time.at(e.value["timestamp"].value).to_s)

      mode = nil

      case e.value["api"].value
        when 1
          mode = "Unique Device ID (UDID)"
        when 2
          mode = "Wifi MAC Address"
        when 3
          mode = "Addressbook (via API)"
        when 4
          mode = "Calendar (via API)"
        when 5
          mode = "Photos / Videos"
        when 6
          mode = "Location"
        when 7
          mode = "Addressbook (File Access)"
        when 8
          mode = "Calendar (File Access)"
        when 9
          mode = "Audio recording"
        when 10
          mode = "Camera"
        when 11
          mode = "General Pasteboard"
        when 12
          mode = "Find Paasteboard"
        when 13
          mode = "Custom Pasteboard"
      end

      row <<   Qt::StandardItem.new(mode)

      row
    end

  end
end
