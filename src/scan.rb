require "date"
require "selenium-interface.rb"
require "util.rb"

class Adserver
  MATCH_FOUND_BUT_NO_ADSERVER_DETECTED = "not detected"
  COMMINDO_MEDIA="commindo-media.de"
end

def _innerHtmlIsMatch( innerHtml, scan )
  if innerHtml =~ /#{scan}/i
    return Adserver::MATCH_FOUND_BUT_NO_ADSERVER_DETECTED
  end
  false
end

def _linkUrlIsMatch( linkUrl, scan )
  # linkIsMatch both:
  #  i) determines if a match exists for the competitor denoted by 'scan'
  # ii) returns the adserver serving the ad 

  if linkUrl =~ /.*commindo-media.*oadest.*#{scan}/ then
    return Adserver::COMMINDO_MEDIA
  elsif linkUrl =~ /#{scan}/i
    return Adserver::MATCH_FOUND_BUT_NO_ADSERVER_DETECTED
  end

  false
end

def _searchHtmlForMatches( html, scan )

  matches = []

  html.scan(/<a.*?\/a>/i) do
    |link|

    re = /<a.*?href="(.*?)".*?>(.*)<.*?\/a>/
    m = re.match(link)
    next unless m
    linkUrl = m[1]
    innerHtml = m[2]
    m = nil # not intended to be used again

    next unless adserver = _linkUrlIsMatch( linkUrl, scan ) || _innerHtmlIsMatch( innerHtml, scan )
    
    match = OpenStruct.new
    match.linkUrl = linkUrl
    match.innerHtml = innerHtml
    match.adserver = adserver
    
    matches.push match
  end

  return matches unless matches.empty?
  false
end



def runScan( urls, scans, options )

  puts "scanning..." if options.verbose
  
  scansWithMatch = {}
  
  options.repeat.times do |i|

    urls.each do |url|

      begin
        browser = browser( url, options.seleniumHost )
        html = getPageSource( browser )
        
        scans.each do |scan|
          next unless matches = _searchHtmlForMatches( html, scan )

          # add current scan to list of scans that have at least one match across all runs/urls
          scansWithMatch[scan] = OpenStruct.new unless scansWithMatch[scan]
          scanResult = scansWithMatch[scan]

          # add current browser page to set of pages containing a match for the current scan
          scanResult.pages = {} unless scanResult.pages
          scanResult.pages[md5(html)] = OpenStruct.new unless scanResult.pages[md5(html)]
          page = scanResult.pages[md5(html)]
          page.html = html
          page.screenshot = pageScreenshot( browser )
          page.url = url

          # add each match on the current browser page to the set of all matches for the scan
          # annotate the matches found with page md5, to associate matches with screenshots
          matches.each do |match|
            match.pageMd5 = md5(html)
            match.url = url
          end
          scanResult.matches = [] unless scanResult.matches
          scanResult.matches = scanResult.matches + matches

        end # scans.each
      ensure
        close browser
      end
    end # urls.each
    
    puts "done run #{i+1} of #{options.repeat}" if options.verbose
  end # options.repeat.times
  
  scansWithMatch
end
