require "date"
require "selenium-interface.rb"

def _detectMatch( html, scan )

  # for now, let's just enumerate through advertising providers
  if false then
    puts "false"

  # commindo-media
  elsif html then
    
  end
  
   http://creatives.commindo-media.de/www/delivery/ck.php?oaparams=2__bannerid=889__zoneid=11__cb=eb4ff9e928__oadest=http%3A%2F%2Fwww.wix.com%2Fstart%2Fwfree%3Futm_campaign%3Dsmashing%26experiment_id%3Dsmashflash19


end



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
            match.html = htlm            match.screenshot = pageScreenshot( browser )
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
