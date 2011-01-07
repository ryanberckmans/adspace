require "timeout"
require "date"
require 'base64'
require "core/util.rb"
require Util.here "selenium-interface.rb"

module Adbot
  class << self
    
    private
    def follow_ad_link_urls( ads, browser, domain, options )
      resolved_link_urls = {}
      ads.each do |ad|
        (ad.target_location = "not-following-ads" and next) unless options.follow_ads
        begin
          (ad.target_location = "no-link-url" and next) unless ad.link_url and ad.link_url.length > 0
          # websites route adverts through their own domain, to valid target_urls. can't just flag them all as no-follow.
          #(ad.target_location = "link-url-points-to-same-domain" and next) if Util::domain_contains_url domain, ad.link_url
          (ad.target_location = "link-url-was-google-adsense" and next) if Util::domain_contains_url "http://google.com", ad.link_url
          (ad.target_location = "link-url-was-google-page-of-ads" and next) if ad.link_url =~ /doubleclick\.net\/pagead\/ads/i
          (ad.target_location = "link-url-is-javascript" and next) if ad.link_url =~ /^javascript/i
          (ad.target_location = "failed-link-url" and next) if ad.link_url =~ /^failed/i
          if resolved_link_urls[ad.link_url]
            ad.target_location = resolved_link_urls[ad.link_url]
            Log::info "link url (#{ad.link_url}) resolved by cache to location::: #{ad.target_location}"
            next
          end
          ad.target_location = SeleniumInterface::get_link_target_location( browser, ad.link_url )
          resolved_link_urls[ad.link_url] = ad.target_location
        rescue Exception => e
          ad.target_location = "error-getting-target-location"
          Log::warn e.backtrace.join "\t"
          Log::warn e.message
          Log::warn "error getting ad target location (#{e.class}, #{e.class.ancestors.join ","}), continuing scan"
        end
      end
    end

    public
    def scan_url( scan_id, options )
      begin
        scan = Scan.find scan_id
      rescue StandardError => e
        Log::error e.backtrace.join "\t"
        Log::error "#{e.class} " + e.message
        return nil
      end

      if not scan.domain or not scan.domain.url
        Log::error "scan #{scan_id} had no associated domain", "adbot"
        return nil
      end
      
      url_result = OpenStruct.new
      url_result.domain = scan.domain.url
      url_result.path = scan.path
      if not url_result.path or url_result.path.length < 1
        url_result.path = "/"
      end

      url_result.scan_time = Time.now

      Util::quantcast_rank url_result

      Log::info "scanning #{url_result.domain + url_result.path} scan_id #{scan_id}", "adbot"
      
      begin
        browser = SeleniumInterface::browser( url_result.domain, options.selenium_host, options.selenium_port )
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

        #url_result.screenshot = SeleniumInterface::page_screenshot browser
        #File.open("/tmp/#{url.split("//")[1].gsub("/", ".")}.png", 'w') {|f| f.write(Base64.decode64(url_result.screenshot))} if url_result.screenshot rescue Log::info "failed to save screenshot"
        
        follow_ad_link_urls( url_result.ads, browser, url_result.domain, options )

        url_result.screenshot = nil
        Log::debug "final struct:"
        Log::debug url_result

      rescue Errno::ECONNREFUSED => e
        Log::fatal "connection to selenium server failed", "adbot"
        raise
      rescue Timeout::Error, StandardError => e
        # Timeout::Error, raised if an http connection times out, derives from Interrupt, which is also the exception for SIGnals.
        # catch Timeout::Error, but re-raise Interrupt so that SIGnals work correctly.
        Log::error e.backtrace.join "\t"
        Log::error "#{e.class} " + e.message
        url_result.exception = e
      rescue Interrupt, SystemExit => e
        Log::fatal "scan.rb: re-raising caught exception: #{e.class} (#{e.class.ancestors.join ","})"
        raise
      rescue Exception => e
        Log::fatal "scan.rb: re-raising unknown exception: #{e.class} (#{e.class.ancestors.join ","})"
        raise
      ensure
        SeleniumInterface::end_session browser
      end 
      
      url_result
    end # def scan_url
  end
end
