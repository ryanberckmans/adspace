require "optparse"
require "ostruct"

def parseOptions( argv )
  collectedOptions = OpenStruct.new

  collectedOptions.repeat = 1
  collectedOptions.seleniumHost = "localhost"
  collectedOptions.humanClient = "no-client"

  opts = OptionParser.new do |opts|
    opts.banner = "Usage: adscan [options]"
    opts.separator ""
    opts.separator "Specific options:"
    
    opts.on("-u", "--url-file FILE", String, "Required. Path to FILE containing a list of URLs to scan, one per line") do |file|
      collectedOptions.urlFile = file
    end

    opts.on("-a", "--advertisers-file FILE", String, "Required. Path to FILE containing advertisers to scan each web page for, one per line (each complete line is an advertiser which is scanned for)") do |file|
      collectedOptions.scanFile = file
    end

    opts.on("-r", "--repeat-num-times INT", Integer, "Optional. Integer specifying how many times to repeat the scanning process for each url (default 1)") do |repeat|
      collectedOptions.repeat = repeat
    end

    opts.on("--selenium-host HOST", String, "Optional. Ip address or domain of selenium server (default localhost)") do |host|
      collectedOptions.seleniumHost = host
    end

    opts.on("-c", "--client CLIENT", String, "Optional. The human customer the scan is being performed for (default no-client)") do |client|
      collectedOptions.humanClient = client
    end    

    opts.on("-v", "--verbose", "Optional. Verbose mode") do
      collectedOptions.verbose = true
    end

    opts.on("-b", "--bail", "Optional. Set everything up but exit instead of connecting to selenium server") do
      collectedOptions.bail = true
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
