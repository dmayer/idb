require_relative '../lib/keychain_plist_parser'

module Idb
  class KeyChainWidget < Qt::TableWidget

    def initialize *args
      super *args
      @layout = Qt::GridLayout.new
      setLayout(@layout)


      @model = Qt::StandardItemModel.new

      @selection_model = Qt::ItemSelectionModel.new @model
      @selection_model.connect(SIGNAL('selectionChanged(QItemSelection,QItemSelection)')) {|x,y|
        unless x.indexes.length == 0
          row = x.indexes[0].row
          text = ""
          text <<  "DATA\n"
          text << "=======================\n"
          text << @keychain.entries[row]["data"].to_s

          text << "\n\nV_DATA\n"
          text << "=======================\n"
          text << @keychain.entries[row]["v_Data"].to_s
          @details.clear
          @details.appendPlainText text

        end

      }

      @keychain_tab = Qt::TableView.new
      @keychain_tab.setModel @selection_model.model
      @keychain_tab.setSelectionModel(@selection_model)

      @keychain_tab.setSelectionBehavior(Qt::AbstractItemView::SelectRows)
      @keychain_tab.setEditTriggers(Qt::AbstractItemView::NoEditTriggers	)

      @layout.addWidget @keychain_tab, 0,0

      @details = Qt::PlainTextEdit.new
      @details.setReadOnly(true)
      @layout.addWidget @details, 1, 0

      @dump = Qt::PushButton.new "Dump Keychain"
      @dump.connect(SIGNAL :released) {
        $device.dump_keychain
        @keychain = KeychainPlistParser.new "tmp/device/genp.plist"
        populate_table
      }
      @layout.addWidget @dump, 2, 0
    end

    def populate_table
      @details.clear
      @model.clear
      @model.setHorizontalHeaderItem(0, Qt::StandardItem.new("Access Group"))
      @model.setHorizontalHeaderItem(1, Qt::StandardItem.new("Account"))
      @model.setHorizontalHeaderItem(2, Qt::StandardItem.new("Service"))
      @model.setHorizontalHeaderItem(3, Qt::StandardItem.new("Protection"))
      @model.setHorizontalHeaderItem(4, Qt::StandardItem.new("Creation"))
      @model.setHorizontalHeaderItem(5, Qt::StandardItem.new("Modification"))


      @keychain.entries.each { |item|
        row = Array.new
        row << Qt::StandardItem.new(item['agrp'].to_s)
        row << Qt::StandardItem.new(item['acct'].to_s)
        row << Qt::StandardItem.new(item['svce'].to_s)
        row << Qt::StandardItem.new(item['protection_class'].to_s)
        row << Qt::StandardItem.new(item['cdat'].to_s)
        row << Qt::StandardItem.new(item['mdat'].to_s)
        @model.appendRow(row)
      }
      @keychain_tab.resizeColumnsToContents
      @keychain_tab.resizeRowsToContents


    end




  end
end