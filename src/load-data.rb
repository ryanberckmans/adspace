
def _loadURLs( urlFile )
  urls = []
  File.foreach( urlFile ) { |url| urls.push url }
  urls
end

def _loadScans( scanFile )
  scans = []
  File.foreach( scanFile ) { |scan| scans.push scan }
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

