require_relative 'certificate_item'

class CAManagerDialog < Qt::Dialog

  def initialize *args
    super *args
    @layout = Qt::GridLayout.new
    setLayout(@layout)
    setWindowTitle("CA Certificate Management")



    @model = Qt::StandardItemModel.new

    @selection_model = Qt::ItemSelectionModel.new @model
    @selection_model.model

    @cert_tab = Qt::TableView.new
    @cert_tab.setModel @selection_model.model
    @cert_tab.setSelectionModel(@selection_model)

    @cert_tab.setSelectionBehavior(Qt::AbstractItemView::SelectRows)
    @cert_tab.setEditTriggers(Qt::AbstractItemView::NoEditTriggers	)


    @selection_model.connect(SIGNAL('selectionChanged(QItemSelection,QItemSelection)')) {|x,y|
      if x.indexes.length == 0
        @delete_button.setEnabled(false)
      else
        @delete_button.setEnabled(true)
        @selected_row = x.indexes[0].row
      end

    }


    @refresh_button = Qt::PushButton.new "Refresh"
    @refresh_button.connect(SIGNAL(:released)) {|x|
      refresh_table
    }

    @delete_button = Qt::PushButton.new "Delete"
    @delete_button.setEnabled(false)
    @delete_button.connect(SIGNAL(:released)) {|x|
      item_containing_cert = @model.takeRow(@selected_row)[0]
      if not item_containing_cert.nil?
        @if.remove_cert item_containing_cert.certificate
      end
      refresh_table
    }


    @import_button = Qt::PushButton.new "Import..."
    @import_button.setToolTip("Import an existing certificate")
    @import_button.connect(SIGNAL(:released)) { |x|
      @file_dialog = Qt::FileDialog.new
      @file_dialog.setAcceptMode(Qt::FileDialog::AcceptOpen)
      filters = Array.new
      filters << "PEM Files (*.pem)"
      filters << "Any files (*)"
      @file_dialog.setNameFilters(filters);

      @file_dialog.connect(SIGNAL('fileSelected(QString)')) { |x|
        begin
          @if.server_cert(x)
        rescue Exception => e
          error = Qt::MessageBox.new self
          error.setInformativeText("Couldn't import certificate")
          error.setDetailedText(e.message)
          error.setIcon(Qt::MessageBox::Critical)
          error.exec
        end
        refresh_table
      }



      @file_dialog.exec
    }

    @close_button = Qt::PushButton.new "Close"
    @close_button.connect(SIGNAL(:released)) {|x|
      @if.stop_cert_server
      reject()
    }

    @layout.addWidget @cert_tab, 0, 0, 4, 4
    @layout.addWidget @refresh_button, 0, 4
    @layout.addWidget @delete_button, 1,4
    @layout.addWidget @import_button, 2,4
    @layout.addItem Qt::SpacerItem.new(0,1, Qt::SizePolicy::Fixed, Qt::SizePolicy::Expanding), 3, 4
    @layout.addWidget @close_button, 4, 4

    @if = $device.ca_interface
    refresh_table



    #setFixedHeight(sizeHint().height());
    setMinimumSize(800,500)
  end

  def refresh_table
    @model.clear
    @model.setHorizontalHeaderItem(0, Qt::StandardItem.new("Subject"))
    @model.setHorizontalHeaderItem(1, Qt::StandardItem.new("Expiry"))
    @model.setHorizontalHeaderItem(2, Qt::StandardItem.new("Issuer"))

    @if.get_certs.each { |cert|
      row = Array.new
      item = CertificateItem.new(cert.subject.to_a.map { |x| "#{x[0]}: #{x[1]}"}.join("\n"))
      item.certificate = cert
      row << item
      row << Qt::StandardItem.new(cert.not_after.to_s)
      row << Qt::StandardItem.new(cert.issuer.to_a.map { |x| "#{x[0]}: #{x[1]}"}.join("\n"))
      @model.appendRow(row)
    }
    @cert_tab.resizeColumnsToContents
    @cert_tab.resizeRowsToContents


    #     puts "#{i.to_s.ljust(2)} - Subject: #{cert.subject}"
    #     puts "     Details: #{cert.inspect}"



  end





end