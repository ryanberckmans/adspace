require 'base64'
require 'set'
require 'util.rb'

def _summary( scansWithMatch, options )
  puts 
  puts "--------------------------"
  puts "summary:"
  puts " (search performed for #{options.humanClient})"
  puts "-------"
  
  scansWithMatch.keys.sort.each do |scan|
    puts "  #{scan} advertises on:"

    scanResult = scansWithMatch[scan]

    urls = Set.new
    
    scanResult.matches.each do
      |match|
      urls.add "#{match.url} (adserver #{match.adserver})"
    end
    
    urls.sort.each do
      |url|
      puts "    #{url}"
    end
  end
end

def _makeClientDirectories( options )
  begin
    FileUtils.mkdir("../client")
  rescue Exception => e
  end

  begin
    FileUtils.mkdir("../client/#{options.humanClient}")
  rescue Exception => e
  end
end

def _makeWebpage( scansWithMatch, options )
  puts
  puts "saving match data to client subdirectory ../client/#{options.humanClient}"

  _makeClientDirectories options
  
  begin
    File.open("../client/#{options.humanClient}/index.html", 'w') do |f|
      
      f.write "<html><head><title>AdChart results for #{options.humanClient}</title><link rel=\"stylesheet\" type=\"text/css\" href=\"../web/styles.css\"></head><body>"

      f.write "<div id=\"header\"><div class=\"content\"> </div> </div>"
      f.write "<div id=\"container\">"
      
      scansWithMatch.keys.sort.each do |scan|
        f.write "<h2>#{scan} advertisements</h2>"
        
        scanResult = scansWithMatch[scan]
        
        urls = {}
        
        scanResult.matches.each do |match|
          urls[match.url] = [] unless urls[match.url]
          urls[match.url].push match
        end

        urls.each_key do
          |url|
          
          f.write "<h3>#{url}:</h3>"

          f.write "<div class=\"ad-list\">"

          uniqueInnerHtml = Set.new
          
          urls[url].each do |match|
            next unless not uniqueInnerHtml.include? match.innerHtml
            uniqueInnerHtml.add match.innerHtml

            f.write "<div class=\"ad-detail\">"
            f.write "  <a href=\"#{match.linkUrl}\" target=\"_blank\"> #{match.innerHtml} </a>"
            f.write "  <p>(#{match.adserver})</p>"
            f.write "</div>"
          end
          f.write "</div>" # ad-list
        end # urls.each_key
      end # each competitor

      f.write "</div>" # container
      f.write "</body></html>"
    end
  rescue Exception => e
    puts "error writing to file"
    raise
  end

  system "google-chrome ./#{options.humanClient}/index.html&"
end

def processMatches( scansWithMatch, options )

  if scansWithMatch.empty? then
    puts "no matches found"
    return
  end

  _makeWebpage( scansWithMatch, options )

  _summary( scansWithMatch, options )
end
