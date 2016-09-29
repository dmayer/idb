require_relative 'ssh_operations'

module Idb
  class ScreenShotUtil
    def initialize(data_path, ops, sim = true)
      @data_path = data_path
      ap @data_path
      @snapshot_path = "#{@data_path}/Library/Caches/Snapshots"
      @ops = ops
      @sim = sim
    end

    def mark
      if @sim
        # create snapshot dir!
        Dir.mkdir_p @snapshot_path unless Dir.exist? @snapshot_path
      end
      mark_time
    end

    def check
      # there should really be only one directory in here which is named
      # based on the bundle id of the app. lets go through all, just in case.

      snap_dirs = @ops.list_dir("#{@snapshot_path}/").reject { |e| e =~ /^\.\.?$/ }

      snap_dirs.each do |dir|
        full_snap_dir = "#{@snapshot_path}/#{dir}"
        next unless @ops.directory? full_snap_dir

        # walk through all files in snaphot dir
        content = @ops.dir_glob(full_snap_dir, "**/*")

        # see if any is younger than mark.
        content.each do |f|
          #          full_path = "#{full_snap_dir}/#{f}"
          full_path = f
          if @ops.file?(full_path) && @ops.mtime(full_path) > @time
            return full_path
          end
        end
      end
      nil
    end

    private

    def mark_time
      @time = Time.now
    end
  end
end
