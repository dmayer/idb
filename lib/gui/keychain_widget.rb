require_relative '../lib/keychain_wrapper'
require_relative 'keychain_tab_widget'
require_relative 'keychain_edit_dialog'
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

        if x.indexes.length == 0
          @delete_button.setEnabled(false)
          @edit_button.setEnabled(false)
          @edit64_button.setEnabled(false)
        else
          @delete_button.setEnabled(true)
          @edit_button.setEnabled(true)
          @edit64_button.setEnabled(true)
          @selected_row = x.indexes[0].row
        end

        unless x.indexes.length == 0
          id =  @model.item(x.indexes[0].row).text
          @keychain_tab_widget.set_data Base64.decode64(@keychain.entries[id.to_i]["Data"])
          @keychain_tab_widget.set_hexdata Base64.decode64(@keychain.entries[id.to_i]["Data"])
          @keychain_tab_widget.set_plist Base64.decode64(@keychain.entries[id.to_i]["Data"])


        end

      }

      @keychain_tab = Qt::TableView.new
      @keychain_tab.setModel @selection_model.model
      @keychain_tab.setSelectionModel(@selection_model)

      @keychain_tab.setSelectionBehavior(Qt::AbstractItemView::SelectRows)
      @keychain_tab.setEditTriggers(Qt::AbstractItemView::NoEditTriggers	)

      @layout.addWidget @keychain_tab, 0,0,1,3


      @dump = Qt::PushButton.new "Dump Keychain"
      @layout.addWidget @dump, 2, 0,1,3

      @dump.connect(SIGNAL :released) {
        populate_table
      }

      @keychain_tab_widget = KeychainTabWidget.new
      @layout.addWidget @keychain_tab_widget, 3, 0,1,3


      @delete_button = Qt::PushButton.new "Delete"
      @delete_button.setEnabled(false)
      @layout.addWidget @delete_button, 4, 0
      @delete_button.connect(SIGNAL :released) {
        service = @keychain.entries[@selected_row+1]["Service"]
        account = @keychain.entries[@selected_row+1]["Account"]
        agroup = @keychain.entries[@selected_row+1]["EntitlementGroup"]

        reply = Qt::MessageBox::question(self, "Delete Keychain Item", "Are you sure to delete the item with<br>service=#{service}<br>account=#{account}<br>group=#{agroup}", Qt::MessageBox::Yes, Qt::MessageBox::No);
        if reply == Qt::MessageBox::Yes
          @keychain.delete_item service, account, agroup

          reply2 = Qt::MessageBox::question(self, "Refresh?", "Item deleted, refresh keychain data?", Qt::MessageBox::Yes, Qt::MessageBox::No);
          if reply2 == Qt::MessageBox::Yes
            populate_table
          end
        end


      }

      @edit_button = Qt::PushButton.new "Edit as Text"
      @edit_button.setEnabled(false)
      @layout.addWidget @edit_button, 4, 1

      @edit_button.connect(SIGNAL :released) {
        service = @keychain.entries[@selected_row+1]["Service"]
        account = @keychain.entries[@selected_row+1]["Account"]
        agroup = @keychain.entries[@selected_row+1]["EntitlementGroup"]
        data = @keychain.entries[@selected_row+1]["Data"]
        dialog = KeychainEditDialog.new
        dialog.connect(SIGNAL :accepted) {

          @keychain.edit_item service, account, agroup, Base64.encode64(dialog.getText)

          reply2 = Qt::MessageBox::question(self, "Refresh?", "Item saved, refresh keychain data?", Qt::MessageBox::Yes, Qt::MessageBox::No);
          if reply2 == Qt::MessageBox::Yes
            populate_table
          end
        }

        dialog.setText Base64.decode64(data)
        dialog.show
      }
      @edit64_button = Qt::PushButton.new "Edit as Base64"
      @edit64_button.setEnabled(false)
      @edit64_button.connect(SIGNAL :released) {
        service = @keychain.entries[@selected_row+1]["Service"]
        account = @keychain.entries[@selected_row+1]["Account"]
        agroup = @keychain.entries[@selected_row+1]["EntitlementGroup"]
        data = @keychain.entries[@selected_row+1]["Data"]
        dialog = KeychainEditDialog.new
        dialog.connect(SIGNAL :accepted) {
          @keychain.edit_item service, account, agroup, dialog.getText

          reply2 = Qt::MessageBox::question(self, "Refresh?", "Item saved, refresh keychain data?", Qt::MessageBox::Yes, Qt::MessageBox::No);
          if reply2 == Qt::MessageBox::Yes
            populate_table
          end
        }

        dialog.setText data
        dialog.show
      }
      @layout.addWidget @edit64_button, 4, 2

    end


    def populate_table
      @keychain = KeychainWrapper.new
      @keychain.parse
      @keychain_tab_widget.clear
      @model.clear
      @model.setHorizontalHeaderItem(0, Qt::StandardItem.new("ID"))
      @model.setHorizontalHeaderItem(1, Qt::StandardItem.new("Entitlement Group"))
      @model.setHorizontalHeaderItem(2, Qt::StandardItem.new("Account"))
      @model.setHorizontalHeaderItem(3, Qt::StandardItem.new("Service"))
      @model.setHorizontalHeaderItem(4, Qt::StandardItem.new("Protection"))
      @model.setHorizontalHeaderItem(5, Qt::StandardItem.new("User Presence"))
      @model.setHorizontalHeaderItem(6, Qt::StandardItem.new("Creation"))
      @model.setHorizontalHeaderItem(7, Qt::StandardItem.new("Modification"))

      @keychain.entries.each { |entry|
        item = entry[1]
        row = Array.new
        id = Qt::StandardItem.new
        id.setData(Qt::Variant.new(entry[0].to_i), Qt::DisplayRole)
        row << id
        row << Qt::StandardItem.new(item['EntitlementGroup'].to_s)
        row << Qt::StandardItem.new(item['Account'].to_s)
        row << Qt::StandardItem.new(item['Service'].to_s)
        row << Qt::StandardItem.new(item['Protection'].to_s)
        row << Qt::StandardItem.new(item['UserPresence'].to_s)
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
