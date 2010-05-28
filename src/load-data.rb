
def _valid( entry )
  return false if entry.lstrip.length < 1
  return false if entry =~ /\#/
  true
end

def _loadURLs( urlFile )
  urls = []
  File.foreach( urlFile ) { |url| urls.push( url.chomp ) if _valid(url) }
  urls
end

def _loadScans( scanFile )
  scans = []
  File.foreach( scanFile ) { |scan| scans.push( scan.chomp ) if _valid(scan) }
  scans
end

def getURLs( options )
  begin
      urls = _loadURLs( options.urlFile )
  rescue Exception => e
    puts e.message
    Process.exit
  end

  urls
end

def getScans( options )
  begin
      scans = _loadScans( options.scanFile )
  rescue Exception => e
    puts e.message
    Process.exit
  end

  scans
end

