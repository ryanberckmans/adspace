require "date"
require "selenium-interface.rb"

def runScan( urls, scans, options )

  puts "scanning..." if options.verbose
  
  matches = {}
  
  options.repeat.times do |i|

    urls.each do |url|

      begin
        browser = browser( url, options.seleniumHost )
        html = getPageSource( browser )
        
        scans.each do |scan|
          if html =~ /#{scan}/i then
            match = OpenStruct.new
            match.url = url
            match.scan = scan
            match.html = html
            match.screenshot = pageScreenshot( browser )
            match.date = Date.today.to_s

            matches[scan] = [] unless matches[scan]
            matches[scan].push match
          end
        end
        
      ensure
        close browser
      end
    end
    
    puts "done run #{i+1} of #{options.repeat}" if options.verbose
  end

  matches
end
