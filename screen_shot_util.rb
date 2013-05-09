class ScreenShotUtil

  def initialize app_path
    @app_path = app_path
    @snapshot_path = "#{@app_path}/Library/Caches/Snapshots"
  end

  def sim_mark
    #create snapshot dir!
    if not Dir.exist? @snapshot_path
      Dir.mkdir @snapshot_path
    end
    mark_time
  end

  def sim_check

    # there should really be only one directory in here which is named
    # based on the bundle id of the app. lets go through all, just in case.
    snap_dirs = Dir.entries("#{@snapshot_path}/").reject {|e| e =~ /^\.\.?$/}

    snap_dirs.each { |dir|
      full_snap_dir = "#{@snapshot_path}/#{dir}"
      if File.directory? full_snap_dir

        # walk through all files in snaphot dir
        content = Dir.entries(full_snap_dir)

        # see if any is younger than mark.
        content.each { |f|
          full_path = "#{full_snap_dir}/#{f}"
          if File.file? full_path and File.mtime(full_path) > @time
              return full_path
          end
        }
      end
    }
    return nil
  end

  private

  def mark_time
    @time = Time.now
  end

end