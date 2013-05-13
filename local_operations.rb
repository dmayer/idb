class LocalOperations


  def file? path
    File.file? path
  end


  def directory? path
   File.directory? path
  end

  def mtime path
    File.mtime path
  end

  def open path
    Launchy.open path
  end

  def list_dir path
    Dir.entries path

  end


end