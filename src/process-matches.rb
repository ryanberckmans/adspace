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

def _write_to_file( scansWithMatch, options )
  puts
  puts "saving match data to client subdirectory ./#{options.humanClient}"

  begin
    FileUtils.mkdir("./#{options.humanClient}")
  rescue Exception => e
  end
  
  begin
    File.open("./#{options.humanClient}/index.html", 'w') do |f|
      
      f.write "<html><head><title>Adscan results for #{options.humanClient}</title></head><body>"

      f.write "<h1>Results Summary:</h1>"
      
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

          uniqueInnerHtml = Set.new
          
          urls[url].each do |match|

            next unless not uniqueInnerHtml.include? match.innerHtml
            uniqueInnerHtml.add match.innerHtml

            f.write "<div class=\"ad-detail\">"
            f.write "  <a href=\"#{match.linkUrl}\"> #{match.innerHtml} </a>"
            f.write "  <br>(#{match.adserver})"
            f.write "</div>"

            
          end
        end
      end
      
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

  _write_to_file( scansWithMatch, options )

  _summary( scansWithMatch, options )
end
