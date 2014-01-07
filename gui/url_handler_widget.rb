require_relative '../lib/url_scheme_fuzzer'

class URLHandlerWidget < Qt::Widget



  def initialize *args
    super *args

    @url_handler_list = Qt::GroupBox.new self
    @url_handler_list.setTitle "List of registered URL Handlers"
    @url_handler_list_layout = Qt::GridLayout.new
    @url_handler_list.setLayout @url_handler_list_layout

    @refresh = Qt::PushButton.new "Refresh"
    @refresh.connect(SIGNAL :released) {
      refresh
    }

    @list = Qt::ListWidget.new self
    @list.connect(SIGNAL('itemDoubleClicked(QListWidgetItem*)')) { |item|
      @url_open_string.text = item.text + "://"
    }

    @url_handler_list_layout.add_widget @list, 0, 0
    @url_handler_list_layout.add_widget @refresh, 1, 0



    @fuzz_config = Qt::GroupBox.new self
    @fuzz_config.setTitle "Fuzzer"
    @fuzz_config_layout = Qt::GridLayout.new
    @fuzz_config.setLayout @fuzz_config_layout

    @fuzz_config_fuzz_strings = Qt::ListWidget.new self
    @fuzz_config_fuzz_strings_label = Qt::Label.new "<b>Fuzz Strings:<b>"
    @fuzzer = URLSchemeFuzzer.new
    @fuzzer.default_fuzz_strings.each { |x|
      @fuzz_config_fuzz_strings.addItem x
    }

    @fuzz_config_new_fuzz = Qt::LineEdit.new
    @fuzz_config_add_fuzz = Qt::PushButton.new "Add"
    @fuzz_config_add_fuzz.connect(SIGNAL :released) {
      @fuzz_config_fuzz_strings.addItem @fuzz_config_new_fuzz.text
      @fuzz_config_new_fuzz.text = ""
      @fuzz_config_remove_fuzz.setEnabled(true)
    }
    @fuzz_config_remove_fuzz = Qt::PushButton.new "Remove"
    @fuzz_config_remove_fuzz.connect(SIGNAL :released) {
      row = @fuzz_config_fuzz_strings.current_row
      @fuzz_config_fuzz_strings.takeItem  row unless row.nil?
      if @fuzz_config_fuzz_strings.count == 0
        @fuzz_config_remove_fuzz.setEnabled(false)
      end
    }


    @fuzz_strings = Qt::GroupBox.new self
    @fuzz_strings.setTitle "Fuzz Strings"
    @fuzz_strings_layout = Qt::GridLayout.new
    @fuzz_strings.setLayout @fuzz_strings_layout
    @fuzz_strings.setFlat(true)

    @fuzz_strings_layout.addWidget @fuzz_config_fuzz_strings, 1,0, 3, 1
    @fuzz_strings_layout.addWidget @fuzz_config_new_fuzz, 1,1
    @fuzz_strings_layout.addWidget @fuzz_config_add_fuzz, 2,1
    @fuzz_strings_layout.addWidget @fuzz_config_remove_fuzz, 3,1



    @fuzz_template = Qt::GroupBox.new self
    @fuzz_template.setTitle "Fuzz Template"
    @fuzz_template_layout = Qt::GridLayout.new
    @fuzz_template.setLayout @fuzz_template_layout
    @fuzz_template.setFlat(true)
    @fuzz_config_template_label = Qt::Label.new "Use $@$ to mark injection fuzz points"
    @fuzz_config_template = Qt::LineEdit.new


    @fuzz_config_button = Qt::PushButton.new "Fuzz"
    @fuzz_config_button.connect(SIGNAL :released) {
      fuzz_strings  = Array.new
      0.upto(@fuzz_config_fuzz_strings.count-1) { |i|
        fuzz_strings << @fuzz_config_fuzz_strings.item(i).text
      }
      input = @fuzzer.generate_inputs @fuzz_config_template.text, fuzz_strings
      input.each { |url|
        #TODO: progress bar
        #TODO: kill app after each run
        #TODO: check for crash report
        @fuzzer.execute url
        sleep 2
      }
    }

    @fuzz_template_layout.addWidget @fuzz_config_template_label, 0,0
    @fuzz_template_layout.addWidget @fuzz_config_template, 1,0
    @fuzz_template_layout.addWidget @fuzz_config_button, 2,0, 1, 2



    @fuzz_config_layout.addWidget @fuzz_strings, 0,0
    @fuzz_config_layout.addWidget @fuzz_template, 1, 0




    @url_open = Qt::GroupBox.new self
    @url_open.setTitle "Open URL"
    @url_open_layout = Qt::GridLayout.new
    @url_open.setLayout @url_open_layout

    @url_open_string = Qt::LineEdit.new
    @url_open_button = Qt::PushButton.new "Open"
    @url_open_button.connect(SIGNAL :released) {
      $device.open_url @url_open_string.text
    }
    @url_open_layout.addWidget @url_open_string, 0,0
    @url_open_layout.addWidget @url_open_button, 1,0

    layout = Qt::GridLayout.new do |v|
      v.add_widget @url_handler_list, 0, 0
      v.add_widget @url_open, 0, 1
      v.add_widget @fuzz_config, 1, 0, 2, 2

    end
    setLayout(layout)
  end

  def refresh
    @list.clear
    url_handlers = $selected_app.get_url_handlers
    url_handlers.each { |x|
      @list.addItem x
    }
  end

  def clear
    @list.clear
  end

end