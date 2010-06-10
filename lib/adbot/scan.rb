require "date"
require "core/util.rb"
require Util.here "selenium-interface.rb"
require Util.here "html-parser.rb"

module Adbot
  class << self
    
    private
    def follow_ad_link_urls( ads, browser )
      ads.each do |ad|
        begin
          ad.target_location = SeleniumInterface::get_link_target_location( browser, ad.link_url ) 
        rescue Exception => e
          puts e.backtrace
          puts e.message
          puts "error getting ad target location, continuing scan"
        end
      end
    end

    def ad_screenshot_info( ads, browser )
      SeleniumInterface::include_browser_util browser
      ads.each do |ad|
        next unless ad.link_url
        ad.screenshot_info = SeleniumInterface::ad_screenshot_info( browser, "a[href='#{ad.link_url}']" )
      end
    end
    
    public
    def scan_url( url, scans, options )
      
      puts "scanning #{url}" if options.verbose

      u = Util::decompose_url url
      return unless u
      domain = u.domain
      path = u.path
      path ||= "/"
      u = nil # not intended to be used again

      url_result = OpenStruct.new
      url_result.url = url
      url_result.domain = domain
      url_result.path = path
      
      begin
        browser = SeleniumInterface::browser( domain, options.selenium_host, options.selenium_port )
        html = SeleniumInterface::get_page_source( browser, path )

        return url_result unless browser and html

        html = Util::unescape_html html
        url_result.html = html

        SeleniumInterface::page_screenshot browser
        url_result.screenshot_s3_key = "stub"

        url_result.ads = Adbot::find_ads html        
        ad_screenshot_info( url_result.ads, browser )
        follow_ad_link_urls( url_result.ads, browser )

      rescue Errno::ECONNREFUSED => e
        puts "connection to selenium server failed"
        raise
      rescue Exception => e
        puts e.backtrace
        puts e.message
        url_result.error_scanning = true
      ensure
        SeleniumInterface::end_session browser
      end 
      
      url_result
    end # def scan_url
  end
end
