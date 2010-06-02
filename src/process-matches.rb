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

def _write_to_file( matches, options )
  puts
  puts "saving match data to client subdirectory ./#{options.humanClient}"

  begin
    FileUtils.mkdir("./#{options.humanClient}")
  rescue Exception => e
  end
  File.open("./#{options.humanClient}/index.html", 'w') do |f|

    f.write("<html><head><title>Adscan results for #{options.humanClient}</title></head><body>(screenshots work in progress)<br>")

    matches.keys.each do |key|
      f.write("<h2>Competitor #{key} advertisements detected:</h2>")

      matches[key].each do
        |match|

        f.write("url: #{match.url}<br>")

        begin
          screenshot = Base64.decode64(match.screenshot)
          screenshotFilename = md5(screenshot)
          
          File.open("./#{options.humanClient}/#{screenshotFilename}.png", 'wb') do |sf|
            sf.write(screenshot)
          end

          f.write("<img src=\"busted.png\" alt=\"screenshot unavailable (work in progress)\"/><br>")
        rescue Exception => e
        end
        
      end
      
    end

    f.write("</body></html>")
  end
end

def processMatches( scansWithMatch, options )

  if scansWithMatch.empty? then
    puts "no matches found"
    return
  end

  #_write_to_file( matches, options )

  _summary( scansWithMatch, options )
end
