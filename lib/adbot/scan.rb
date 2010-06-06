require "date"
require "core/selenium-interface.rb"
require "core/util.rb"

module Adbot
  class << self
    
    private
    
    class Adserver
      MATCH_FOUND_BUT_NO_ADSERVER_DETECTED = "no adserver"
      COMMINDO_MEDIA="commindo-media.de"
    end
    
    def inner_html_is_match( inner_html, scan )
      if inner_html =~ /#{scan}/i
        return Adserver::MATCH_FOUND_BUT_NO_ADSERVER_DETECTED
      end
      false
    end
    
    def link_url_is_match( link_url, scan )
      # link_is_match both:
      #  i) determines if a match exists for the competitor denoted by 'scan'
      # ii) returns the adserver serving the ad 
      
      if link_url =~ /.*commindo-media.*oadest.*#{scan}/ then
        return Adserver::COMMINDO_MEDIA
      elsif link_url =~ /#{scan}/i
        return Adserver::MATCH_FOUND_BUT_NO_ADSERVER_DETECTED
      end
      
      false
    end
    
    def search_html_for_matches( html, scan )
      
      matches = []
      
      html.scan(/<a.*?\/a>/i) do
        |link|
        
        re = /<a.*?href="(.*?)".*?>(.*)<.*?\/a>/i
        m = re.match(link)
        next unless m
        link_url = m[1]
        inner_html = m[2]
        m = nil # not intended to be used again
        
        next unless adserver = link_url_is_match( link_url, scan ) || inner_html_is_match( inner_html, scan )
        
        match = OpenStruct.new
        match.link_url = link_url
        match.inner_html = inner_html
        match.adserver = adserver
        
        matches.push match
      end
      
      return matches unless matches.empty?
      false
    end
    
    def decompose( url )
      url.sub!( /%2F/i, "/" )
      re = /^(.*?\/\/.*?)(\/.*)?$/i
      m = re.match(url)
      return unless m
      OpenStruct.new( { "domain" => m[1], "path" => m[2] } )
    end
    
    public
    
    def scan_url( url, scans, options, scans_with_match )
      
      puts "scanning #{url}" if options.verbose
      
      u = decompose url
      return unless u
      domain = u.domain
      path = u.path
      path ||= "/"
      u = nil # not intended to be used again
      
      options.repeat.times do |i|
        
        begin
          browser = SeleniumInterface::browser( domain, options.selenium_host )
          html = SeleniumInterface::get_page_source( browser, path )
          
          next unless browser and html
          
          scans.each do |scan|
            next unless matches = search_html_for_matches( html, scan )
            
            # add current scan to list of scans that have at least one match across all runs/urls
            scans_with_match[scan] ||= OpenStruct.new
            scan_result = scans_with_match[scan]
            
            # add current browser page to set of pages containing a match for the current scan
            scan_result.pages ||= {}
            scan_result.pages[md5(html)] ||= OpenStruct.new
            page = scan_result.pages[md5(html)]
            page.html = html
            page.screenshot = SeleniumInterface::page_screenshot( browser )
            page.url = url
            
            # add each match on the current browser page to the set of all matches for the scan
            # annotate the matches found with page md5, to associate matches with screenshots
            matches.each do |match|
              match.page_md5 = md5(html)
              match.url = url
            end
            scan_result.matches ||= []
            scan_result.matches = scan_result.matches + matches
            
          end # scans.each
        ensure
          begin
            SeleniumInterface::close browser
          rescue Exception => e
            puts e.message
            puts "error closing browser"
          end
        end
        
        puts "done run #{i+1} of #{options.repeat} for #{url}" if options.verbose and options.repeat > 1
      end # options.repeat.times
    end
  end
end
