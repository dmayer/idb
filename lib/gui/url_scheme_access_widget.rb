require_relative "url_access_watcher_thread.rb"
require 'json'

module Idb

  class UrlSchemeAccessWidget < Qt::Widget
    signals "selected_url_changed(QString)"
    def initialize args
      super *args

      @layout = Qt::GridLayout.new
      setLayout(@layout)

      @model = Qt::StandardItemModel.new

      @selection_model = Qt::ItemSelectionModel.new @model
      @selection_model.connect(SIGNAL('selectionChanged(QItemSelection,QItemSelection)')) {|x,y|
        unless x.indexes.length == 0
          row = x.indexes[0].row
          emit selected_url_changed(@model.item(row,2).text)
        end

      }

      @urls_tab = Qt::TableView.new
      @urls_tab.setModel @selection_model.model
      @urls_tab.setSelectionModel(@selection_model)

      @urls_tab.setSelectionBehavior(Qt::AbstractItemView::SelectRows)
      @urls_tab.setEditTriggers(Qt::AbstractItemView::NoEditTriggers	)

      @layout.addWidget @urls_tab, 0,0

      create_table


      @stop = Qt::PushButton.new "Stop"
      @stop.setEnabled(false)
      @stop.connect(SIGNAL :released) {
        @start.setEnabled(true)
        @stop.setEnabled(false)
        stop_log
      }

      @start = Qt::PushButton.new "Start"
      @start.connect(SIGNAL :released) {
        #TODO
        unless $device.pbwatcher_installed?
          error = Qt::MessageBox.new
          error.setInformativeText("pbwatcher not found on the device. Please visit the status dialog and install it.")
          error.setIcon(Qt::MessageBox::Critical)
          error.exec
        else
          @start.setEnabled(false)
          @stop.setEnabled(true)
          launch_process
        end
      }

      @layout.addWidget @start, 1, 0, 1, 1
      @layout.addWidget @stop, 2, 0, 1, 1
    end

    def launch_process
      @urlwatcher_thread = URLWatcherThread.new
      @urlwatcher_thread.connect(SIGNAL('new_entry(QString)')) {|line|
        matches = /(\d{2}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) - (.*)/.match line
        unless matches.nil?
          date = matches[1]
          json = matches[2]
          puts "Date: #{date}"
          puts "JSON: #{json}"
          begin
            data = JSON.parse(json.strip)
            row = Array.new
            row << Qt::StandardItem.new(date.to_s)
            row << Qt::StandardItem.new(data['UIApplicationLaunchOptionsSourceApplicationKey'].to_s)
            row << Qt::StandardItem.new(data["UIApplicationLaunchOptionsURLKey"].to_s)
            @model.appendRow(row)
            @urls_tab.resizeColumnsToContents
            @urls_tab.resizeRowsToContents
          rescue
            $log.error "Couldn't parse #{json.strip}"
          end
        end
      }
      @urlwatcher_thread.start_urlwatcher_thread
    end

    def stop_log
      @urlwatcher_thread.stop
    end

    def create_table
      @model.clear
      @model.setHorizontalHeaderItem(0, Qt::StandardItem.new("Time"))
      @model.setHorizontalHeaderItem(1, Qt::StandardItem.new("Calling Application"))
      @model.setHorizontalHeaderItem(2, Qt::StandardItem.new("URL called"))
    end


  end

end