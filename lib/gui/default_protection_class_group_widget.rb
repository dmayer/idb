module Idb
  class DefaultProtectionClassGroupWidget < Qt::GroupBox
    def initialize(args)
      super(*args)

      setTitle  "Default Data Protection"

      @layout = Qt::GridLayout.new
      label = Qt::Label.new "<b>Default Data Protection</b>", self, 0
      @val = Qt::Label.new "No default set in the entitlements of this app.", self, 0
      @layout.addWidget label, 0, 0
      @layout.addWidget @val, 0, 1
      spacer_horizontal = Qt::SpacerItem.new 0, 1, Qt::SizePolicy::Expanding, Qt::SizePolicy::Fixed
      @layout.addItem spacer_horizontal, 0, 2

      setLayout @layout
    end

    def update
      if $device.ios_version < 8
        @val.setText "Only available for iOS 8+"
      else
        $selected_app.entitlements.each do |x|
          if x[0].to_s == "com.apple.developer.default-data-protection"
            @val.setText x[1].to_s
          end
        end
      end
    end
  end
end
