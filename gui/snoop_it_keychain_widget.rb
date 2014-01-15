require_relative 'snoop_it_update_thread'
require_relative '../lib/snoop_it_wrapper'

class SnoopItKeychainWidget < Qt::Widget

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

    @snoop = SnoopItWrapper.new


    @selection_model.connect(SIGNAL('selectionChanged(QItemSelection,QItemSelection)')) {|x,y|
      selected_row = x.indexes[0].row
      id =  @model.item(selected_row, 0).text
      details = @snoop.keychain_details id
      puts details[0].inspect
      @query_val.setText(details[0]["query"].to_s)
      @data_val.setText(details[0]["data"].to_s)
    }


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

    @details = Qt::GroupBox.new
    @details.setTitle "Details"
    @detail_layout = Qt::GridLayout.new
    @details.setLayout(@detail_layout)

    @query_label = Qt::Label.new  "<b>Query</b>", @details
    @query_val = Qt::Label.new  "", self, 0
    @detail_layout.addWidget @query_label, 0, 0
    @detail_layout.addWidget @query_val, 0, 1


    @data_label = Qt::Label.new  "<b>Data</b>", @details
    @data_val = Qt::Label.new  "", self, 0
    @detail_layout.addWidget @data_label, 1, 0
    @detail_layout.addWidget @data_val, 1, 1






    layout = Qt::VBoxLayout.new do |v|
      v.add_widget(@events_tab)
      v.add_widget(@details)
      v.add_widget(@start)
      v.add_widget(@stop)
    end
    setLayout(layout)



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
    @thread.stream 'keychain_after_id'

  end


  private
  def parse_event e
    row = Array.new
    row <<   Qt::StandardItem.new(e.value["id"].value.to_s)

    row <<   Qt::StandardItem.new(Time.at(e.value["timestamp"].value).to_s)

    mode = nil

    case e.value["action"].value
      when 1
        mode = "Added"
      when 2
        mode = "Modified"
      when 3
        mode = "Deleted"
      when 4
        mode = "Read"
    end

    row <<   Qt::StandardItem.new(mode)

    sec_class = nil
    case e.value["secClass"].value
      when 0
        sec_class = "Unknown"
      when 1
        sec_class = "kSecClassGenericPassword"
      when 2
        sec_class = "kSecClassInternetPassword"
      when 3
        sec_class = "kSecClassCertificate"
      when 4
        sec_class = "kSecClassKey"
      when 5
        sec_class = "kSecClassIdentity"
    end
    row <<   Qt::StandardItem.new(sec_class)

    access = nil
    case e.value["accessible"].value
      when 0
        access = "Unkown"
      when 1
        access = "kSecAttrAccessibleWhenUnlocked"
      when 2
        access = "kSecAttrAccessibleAfterFirstUnlock"
      when 3
        access = "kSecAttrAccessibleAlways"
      when 4
        access = "kSecAttrAccessibleWhenUnlockedThisDeviceOnly"
      when 5
        access = "kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly"
      when 6
        access = "kSecAttrAccessibleAlwaysThisDeviceOnly"
    end
    row <<   Qt::StandardItem.new(access)

    row
  end



end