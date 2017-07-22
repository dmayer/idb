module Idb
  class URLSchemeFuzzWidget < Qt::Widget

    def initialize *args
      super *args

      @fuzz_config_layout = Qt::GridLayout.new
      setLayout @fuzz_config_layout

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

      @fuzz_strings_layout.addWidget @fuzz_config_fuzz_strings, 1,0, 1, 2
      @fuzz_strings_layout.addWidget @fuzz_config_new_fuzz, 2,0, 1 ,2
      @fuzz_strings_layout.addWidget @fuzz_config_add_fuzz, 3,0
      @fuzz_strings_layout.addWidget @fuzz_config_remove_fuzz, 3,1



      @fuzz_template = Qt::GroupBox.new self
      @fuzz_template.setTitle "Fuzz Template"
      @fuzz_template_layout = Qt::GridLayout.new
      @fuzz_template.setLayout @fuzz_template_layout
      @fuzz_config_template_label = Qt::Label.new "Use $@$ to mark injection fuzz points"
      @fuzz_config_template = Qt::LineEdit.new


      @fuzz_config_button = Qt::PushButton.new "Fuzz"
      @fuzz_config_button.connect(SIGNAL :released) {
        @fuzzer.delete_old_reports


        fuzz_strings  = Array.new
        0.upto(@fuzz_config_fuzz_strings.count-1) { |i|
          fuzz_strings << @fuzz_config_fuzz_strings.item(i).text
        }
        input = @fuzzer.generate_inputs @fuzz_config_template.text, fuzz_strings
        input.each { |url|
          if url.nil?
            $log.warn "Skipping nil URL"
            next
          end
          #TODO: progress bar
          #TODO: kill app after each run
          #TODO: check for crash report
          crashed = @fuzzer.execute url
          @log_window.append_message "#{url}\t#{crashed}"
          break if crashed
          Qt::CoreApplication.processEvents
          sleep 2
          Qt::CoreApplication.processEvents
        }
      }

      @fuzz_template_layout.addWidget @fuzz_config_template_label, 0,0
      @fuzz_template_layout.addWidget @fuzz_config_template, 1,0
      @fuzz_template_layout.addWidget @fuzz_config_button, 2,0, 1, 2


      @fuzz_result = Qt::GroupBox.new self
      @fuzz_result.setTitle "Results"
      @fuzz_result_layout = Qt::GridLayout.new
      @fuzz_result.setLayout @fuzz_result_layout
      @log_window = LogPlainTextEdit.new
      @log_window.setReadOnly(true)
      @fuzz_result_layout.addWidget @log_window, 0,0


      @fuzz_config_layout.addWidget @fuzz_strings, 0,0
      @fuzz_config_layout.addWidget @fuzz_template, 1, 0
      @fuzz_config_layout.addWidget @fuzz_result, 0, 1, 2, 1





  end


  end
end
