require "optparse"
require "ostruct"

def parseOptions( argv )
  collectedOptions = OpenStruct.new

  opts = OptionParser.new do |opts|
    opts.banner = "Usage: adscan [options]"
    opts.separator ""
    opts.separator "Specific options:"
    
    opts.on("-u", "--url-file FILE", String, "Required. Path to FILE containing a list of URLs to scan, one per line") do |file|
      collectedOptions.urlFile = file
    end

    opts.on("-s", "--scan-file FILE", String, "Required. Path to FILE containing strings to scan each web page for, one per line (each complete line is a string which is scanned for)") do |file|
      collectedOptions.scanFile = file
    end

    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end

  begin 
    opts.parse!(argv)
  rescue OptionParser::ParseError => e
    puts e.message
    puts
    puts opts
    return
  end
  
  if not collectedOptions.urlFile
    puts "missing required option: --url-file"
    puts
    puts opts
    return
  end

  if not collectedOptions.scanFile
    puts "missing required option: --scan-file"
    puts
    puts opts
    return
  end
  
  collectedOptions
end
