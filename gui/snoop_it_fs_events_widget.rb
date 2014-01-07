require_relative '../lib/snoop_it_wrapper'
require_relative 'snoop_it_update_thread'
require_relative 'qt_ruby_variant'


#TODO: implement something like this to make model update faster
class FSEventItemModel < Qt::StandardItemModel
  def initialize *args
    super *args
  end

  def add_bulk


  end



end



class SnoopItFSEventsWidget < Qt::Widget


  def initialize *args
    super *args

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
    @thread.delete_all
    @thread.stream 'fsevents_after_id'

  end


  private
  def parse_event e
    row = Array.new
    row <<   Qt::StandardItem.new(e.value["id"].value.to_s)

    row <<   Qt::StandardItem.new(Time.at(e.value["timestamp"].value).to_s)

    mode = nil

    case e.value["accessMode"].value
      when 0
        mode = "Error"
      when 1
        mode = "Read-Only"
      when 2
        mode = "Write-Only"
      when 3
        mode = "Read/Write"
    end

    row <<   Qt::StandardItem.new(mode)

    row <<   Qt::StandardItem.new(e.value["path"].value.to_s)

    dp_class = nil
    case e.value["class"].value
      when 1
        dp_class = "NSFileProtectionNone"
      when 2
        dp_class = "NSFileProtectionComplete"
      when 3
        dp_class = "NSFileProtectionCompleteUnlessOpen"
      when 4
        dp_class = "NSFileProtectionCompleteUntilFirstUserAuthentication"
    end
    row <<   Qt::StandardItem.new(dp_class)



    row <<   Qt::StandardItem.new(e.value["sandbox"].value.to_s)
    row
  end



end