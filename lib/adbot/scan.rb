require "timeout"
require "date"
require 'base64'
require "core/util.rb"
require Util.here "selenium-interface.rb"

module Adbot
  class << self
    
    private
    def follow_ad_link_urls( ads, browser, domain, options )
      ads.each do |ad|
        (ad.target_location = "not-following-ads" and next) unless options.follow_ads
        begin
          (ad.target_location = "no-link-url" and next) unless ad.link_url and ad.link_url.length > 0
          (ad.target_location = "link-url-points-to-same-domain" and next) if Util::domain_contains_url domain, ad.link_url
          (ad.target_location = "link-url-was-google-adsense" and next) if Util::domain_contains_url "http://google.com", ad.link_url
          (ad.target_location = "link-url-was-google-page-of-ads" and next) if ad.link_url =~ /doubleclick\.net\/pagead\/ads/i
          (ad.target_location = "link-url-is-javascript" and next) if ad.link_url =~ /^javascript/i
          (ad.target_location = "failed-link-url" and next) if ad.link_url =~ /^failed/i
          ad.target_location = SeleniumInterface::get_link_target_location( browser, ad.link_url ) 
        rescue Exception => e
          ad.target_location = "error-getting-target-location"
          puts e.backtrace
          puts e.message
          puts "error getting ad target location, continuing scan"
        end
      end
    end

    public
    def scan_url( url, options )
      
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
        raise unless browser

        if url_result.path.length > 0
          SeleniumInterface::open_page( browser, url_result.path )
        else
          SeleniumInterface::open_page browser
        end

        html = SeleniumInterface::get_page_source browser
        raise unless html

        html = Util::unescape_html html rescue html
        url_result.html = html

        SeleniumInterface::include_browser_util browser

        url_result.ads = SeleniumInterface::get_ads browser
        url_result.page_width = SeleniumInterface::page_width browser
        url_result.page_height = SeleniumInterface::page_height browser
        url_result.title = SeleniumInterface::page_title browser
        url_result.date = Time.now.to_f.to_s

        url_result.screenshot = SeleniumInterface::page_screenshot browser
        File.open("/tmp/#{url_result.url.split("//")[1].gsub("/", ".")}.png", 'w') {|f| f.write(Base64.decode64(url_result.screenshot))} if url_result.screenshot rescue puts "failed to save screenshot"
        
        follow_ad_link_urls( url_result.ads, browser, url_result.domain, options )

        Util::quantcast_rank url_result

        url_result.html = nil
        url_result.screenshot = nil
        if options.verbose
          puts "final struct:"
          puts url_result
          url_result.ads.each { |ad|
            puts ad.target_location
          }
        end

      rescue Errno::ECONNREFUSED => e
        puts "connection to selenium server failed"
        raise
      rescue Timeout::Error, StandardError => e
        # Timeout::Error, raised if an http connection times out, derives from Interrupt, which is also the exception for SIGnals.
        # catch Timeout::Error, but re-raise Interrupt so that SIGnals work correctly.
        puts e.backtrace
        puts e.message
        url_result.error_scanning = true
        url_result.exception = e
      rescue Interrupt, SystemExit
        raise
      ensure
        SeleniumInterface::end_session browser
      end 
      
      url_result
    end # def scan_url
  end
end
