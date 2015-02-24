require_relative '../lib/keychain_plist_parser'
require_relative 'keychain_tab_widget'
require 'base64'

module Idb

  class KeychainWidget < Qt::Widget

    def initialize *args
      super *args
      @layout = Qt::GridLayout.new
      setLayout(@layout)


      @model = Qt::StandardItemModel.new

      @selection_model = Qt::ItemSelectionModel.new @model
      @selection_model.connect(SIGNAL('selectionChanged(QItemSelection,QItemSelection)')) {|x,y|
        unless x.indexes.length == 0
          id =  @model.item(x.indexes[0].row).text
          @keychain_tab_widget.set_data Base64.decode64(@keychain.entries[id.to_i]["Data"])
        end

      }

      @keychain_tab = Qt::TableView.new
      @keychain_tab.setModel @selection_model.model
      @keychain_tab.setSelectionModel(@selection_model)

      @keychain_tab.setSelectionBehavior(Qt::AbstractItemView::SelectRows)
      @keychain_tab.setEditTriggers(Qt::AbstractItemView::NoEditTriggers	)

      @layout.addWidget @keychain_tab, 0,0


      @dump = Qt::PushButton.new "Dump Keychain"
      @layout.addWidget @dump, 2, 0

      @keychain_tab_widget = KeychainTabWidget.new
      @layout.addWidget @keychain_tab_widget, 3, 0

      @dump.connect(SIGNAL :released) {
        @keychain = KeychainPlistParser.new $device.dump_keychain
        populate_table
      }

    end


    def populate_table
      @keychain_tab_widget.clear
      @model.clear
      @model.setHorizontalHeaderItem(0, Qt::StandardItem.new("ID"))
      @model.setHorizontalHeaderItem(1, Qt::StandardItem.new("Entitlement Group"))
      @model.setHorizontalHeaderItem(2, Qt::StandardItem.new("Account"))
      @model.setHorizontalHeaderItem(3, Qt::StandardItem.new("Service"))
      @model.setHorizontalHeaderItem(4, Qt::StandardItem.new("Protection"))
      @model.setHorizontalHeaderItem(5, Qt::StandardItem.new("Creation"))
      @model.setHorizontalHeaderItem(6, Qt::StandardItem.new("Modification"))

      @keychain.entries.each { |entry|
        item = entry[1]
        row = Array.new
        id = Qt::StandardItem.new
        id.setData(Qt::Variant.new(entry[0].to_i), Qt::DisplayRole)
        row << id
        row << Qt::StandardItem.new(item['Entitlement Group'].to_s)
        row << Qt::StandardItem.new(item['Account'].to_s)
        row << Qt::StandardItem.new(item['Service'].to_s)
        row << Qt::StandardItem.new(item['Protection'].to_s)
        row << Qt::StandardItem.new(item['Creation Time'].to_s)
        row << Qt::StandardItem.new(item['Modified Time'].to_s)
        @model.appendRow(row)
      }
      @keychain_tab.resizeColumnsToContents
      @keychain_tab.resizeRowsToContents
      @keychain_tab.sortByColumn(0, Qt::AscendingOrder)


    end

  end
end
