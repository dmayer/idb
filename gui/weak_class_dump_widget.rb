require_relative '../lib/weak_class_dump_wrapper'

class WeakClassDumpWidget < Qt::Widget
  def initialize *args
    super  *args



    @layout = Qt::GridLayout.new
    setLayout @layout

    @run = Qt::PushButton.new "Dump Classes"
    @layout.addWidget @run, 0,0
    @run.connect(SIGNAL :released) {
      run_cycript
    }


    @results = Qt::PushButton.new "List Results"
    @layout.addWidget @results, 0,1

    @results.connect(SIGNAL :released) {
      @weak_class_dump_wrapper.pull_header_files
      refresh_header_list
    }

    @open_folder = Qt::PushButton.new "Open Folder"
    @layout.addWidget @open_folder, 0,2

    @open_folder.connect(SIGNAL :released) {
      Launchy.open @local_path
    }


    @header_list = Qt::ListWidget.new self
    @header_list_label = Qt::Label.new "<b>Header Files:<b>"
    @header_list.connect(SIGNAL('itemClicked(QListWidgetItem*)')) { |item|
      @content.clear
      @content.appendHtml(CodeRay.scan_file(@local_path + "/" + item.text).page(
        :line_numbers => nil,
        :css => :style
      ))
    }

    @header_list.connect(SIGNAL('itemDoubleClicked(QListWidgetItem*)')) { |item|
      $device.ops.open @local_path + "/" + item.text
    }

    @content = Qt::PlainTextEdit.new
    @content.setReadOnly(true)

    @splitter = Qt::Splitter.new
    @splitter.addWidget @header_list
    @splitter.addWidget @content
    @splitter.setStretchFactor 1, 1.5
    @splitter.setSizePolicy(Qt::SizePolicy::Expanding, Qt::SizePolicy::Expanding)
    @layout.addWidget @splitter, 1, 0, 1, 3

  end

  def run_cycript
    @local_path  = "#{$selected_app.cache_dir}/weak_class_dump_headers"
    @weak_class_dump_wrapper = WeakClassDumpWrapper.new @local_path
    @weak_class_dump_wrapper.execute_cycript

    error = Qt::MessageBox.new
    error.setInformativeText("Cycript dumping the class information... This may take some time. On success the device will play the lock sound. You can then list the header files and view them.")
    error.setIcon(Qt::MessageBox::Information)
    error.exec

  end

  def refresh_header_list
      @header_list.clear
      @weak_class_dump_wrapper.get_header_files.each { |x|
        @header_list.addItem x
      }
  end


  def refresh
    unless $selected_app.cache_dir.nil?
      @local_path  = "#{$selected_app.cache_dir}/weak_class_dump_headers"
      @weak_class_dump_wrapper = WeakClassDumpWrapper.new @local_path
      end
  end
end