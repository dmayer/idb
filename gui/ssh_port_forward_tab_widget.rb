class SSHPortForwardTabWidget < Qt::TabWidget
  def initialize *args
    super *args
    setup_remote_port_forward
    setup_local_port_forward
    @forwarders_changed = false
  end


  def add_remote_forward_to_list remote_port, local_port, local_host
    @remote_forward_list.addItem Qt::ListWidgetItem.new "remote:#{remote_port} -> #{local_host}:#{local_port}"
  end

  def add_local_forward_to_list local_port, remote_port, remote_host
    @local_forward_list.addItem Qt::ListWidgetItem.new "local:#{local_port} -> #{remote_host}:#{remote_port}"
  end


  def setup_local_port_forward
    @local_forward_tab = Qt::Widget.new self
    forward_config_layout = Qt::GridLayout.new
    @local_forward_tab.setLayout forward_config_layout
    addTab(@local_forward_tab,"Local")

    @local_forward_tab.setLayout(forward_config_layout)

    @local_forward_list = Qt::ListWidget.new @local_forward_tab
    forward_config_layout.addWidget @local_forward_list, 0, 0, 2, 2


    if $settings['local_forwards'].nil?
      $settings['local_forwards'] = Array.new
    end

    $settings['local_forwards'].each {|x|
      add_local_forward_to_list x['local_port'], x['remote_port'], x['remote_host']
    }


    add_forward_button = Qt::PushButton.new "Add"
    add_forward_button.connect(SIGNAL(:released)) {
      local_port = @local_local_port_text.text
      remote_port = @local_remote_port_text.text
      remote_host = @local_remote_host_text.text

      if is_valid_port(remote_port) and is_valid_port(local_port)
        @forwarders_changed = true
        add_local_forward_to_list local_port, remote_port, remote_host

        item = Hash.new
        item['local_port'] = @local_local_port_text.text
        item['remote_port'] = @local_remote_port_text.text
        item['remote_host'] = @local_remote_host_text.text
        $settings['local_forwards'] << item
        $settings.store


        @local_local_port_text.text = ""
        @local_remote_port_text.text = ""
        @local_remote_host_text.text = ""
      end
    }
    remove_forward_button = Qt::PushButton.new "Remove"
    remove_forward_button.connect(SIGNAL(:released)) {
      unless @local_forward_list.current_row.nil?
        @forwarders_changed = true
        row = @local_forward_list.current_row
        @local_forward_list.takeItem  row
        $settings['local_forwards'].delete_at(row)
        $settings.store
      end

    }

    forward_config_layout.addWidget add_forward_button, 0, 3
    forward_config_layout.addWidget remove_forward_button, 1, 3

    local_port_label = Qt::Label.new "Local Port"
    @local_local_port_text = Qt::LineEdit.new


    remote_host_label = Qt::Label.new "Remote Host"
    @local_remote_host_text = Qt::LineEdit.new


    remote_port_label = Qt::Label.new "Remote Port"
    @local_remote_port_text = Qt::LineEdit.new

    forward_config_layout.addWidget local_port_label, 2, 0
    forward_config_layout.addWidget @local_local_port_text, 2, 1


    forward_config_layout.addWidget remote_host_label, 3, 0
    forward_config_layout.addWidget @local_remote_host_text, 3, 1


    forward_config_layout.addWidget remote_port_label, 4, 0
    forward_config_layout.addWidget @local_remote_port_text, 4, 1

  end



  def setup_remote_port_forward
    @remote_forward_tab = Qt::Widget.new self
    forward_config_layout = Qt::GridLayout.new
    @remote_forward_tab.setLayout forward_config_layout
    addTab(@remote_forward_tab,"Remote")

    @remote_forward_tab.setLayout(forward_config_layout)


    @remote_forward_list = Qt::ListWidget.new @forward_config
    forward_config_layout.addWidget @remote_forward_list, 0, 0, 2, 2


    if $settings['remote_forwards'].nil?
      $settings['remote_forwards'] = Array.new
    end

    $settings['remote_forwards'].each {|x|
      add_remote_forward_to_list x['remote_port'], x['local_port'], x['local_host']
    }


    add_forward_button = Qt::PushButton.new "Add"
    add_forward_button.connect(SIGNAL(:released)) {
      remote_port = @remote_remote_port_text.text
      local_port = @remote_local_port_text.text
      local_host = @remote_local_host_text.text

      if is_valid_port(remote_port) and is_valid_port(local_port)
        add_remote_forward_to_list remote_port, local_port, local_host
        @forwarders_changed = true

        item = Hash.new
        item['remote_port'] = @remote_remote_port_text.text
        item['local_port'] = @remote_local_port_text.text
        item['local_host'] = @remote_local_host_text.text
        $settings['remote_forwards'] << item
        $settings.store


        @remote_remote_port_text.text = ""
        @remote_local_port_text.text = ""
        @remote_local_host_text.text = ""
      end
    }
    remove_forward_button = Qt::PushButton.new "Remove"
    remove_forward_button.connect(SIGNAL(:released)) {
      if not @remote_forward_list.current_row.nil?
        @forwarders_changed = true
        row = @remote_forward_list.current_row
        @remote_forward_list.takeItem  row
        $settings['remote_forwards'].delete_at(row)
        $settings.store
      end

    }

    forward_config_layout.addWidget add_forward_button, 0, 3
    forward_config_layout.addWidget remove_forward_button, 1, 3

    remote_port_label = Qt::Label.new "Remote Port"
    @remote_remote_port_text = Qt::LineEdit.new


    local_host_label = Qt::Label.new "Local Host"
    @remote_local_host_text = Qt::LineEdit.new


    local_port_label = Qt::Label.new "Local Port"
    @remote_local_port_text = Qt::LineEdit.new

    forward_config_layout.addWidget remote_port_label, 2, 0
    forward_config_layout.addWidget @remote_remote_port_text, 2, 1


    forward_config_layout.addWidget local_host_label, 3, 0
    forward_config_layout.addWidget @remote_local_host_text, 3, 1


    forward_config_layout.addWidget local_port_label, 4, 0
    forward_config_layout.addWidget @remote_local_port_text, 4, 1

  end


  def is_valid_port port
    begin
      if not Integer(port) or Integer(port) > 2**16 or Integer(port) < 1
        return false
      else
        return true
      end
    rescue
      false
    end
  end
end