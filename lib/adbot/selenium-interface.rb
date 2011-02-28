require "rubygems"
require "selenium/client"
require "core/util.rb"

module SeleniumInterface

  ADBOT_JQUERY_FILE = "adbot-jquery-noconflict.js"
  JQUERY_FILE = "jquery-1.4.2.min.js"
  BROWSER_UTIL_SCRIPT_FILE = "browser-util.js"

  ADBOT_JQUERY_SCRIPT = File.read( Util.here( ADBOT_JQUERY_FILE ) )
  JQUERY_SCRIPT = File.read( Util.here( JQUERY_FILE ) )
  BROWSER_UTIL_SCRIPT = File.read( Util.here( BROWSER_UTIL_SCRIPT_FILE ) )

  MAX_ADS = 100
  MAX_FRAME_DEPTH = 10

  class << self

    MINI_PAGE_TIMEOUT = 40 # seconds
    PAGE_TIMEOUT = 160 # seconds
    DEFAULT_TIMEOUT = 300 # seconds, also used as http read timeout for selenium server connection

    MILLIS_IN_SECOND = 1000
    def in_milliseconds( t )
      return t * MILLIS_IN_SECOND
    end

    def end_session( browser )
      begin
        browser.close_current_browser_session if browser
      rescue Exception => e
        Log::error e.backtrace.join "\t"
        Log::error "#{e.class} #{Util::strip_newlines e.message}"
        Log::error "error ending browser session"
      end
    end

    def browser( domain, selenium_host, selenium_port )
      begin
        browser = Selenium::Client::Driver.new \
        :host => selenium_host,
        :port => selenium_port,
        :browser => "*firefox",
        :url => domain,
        :timeout_in_seconds => DEFAULT_TIMEOUT

        browser.start_new_browser_session
        browser.set_timeout in_milliseconds PAGE_TIMEOUT # use PAGE_TIMEOUT as default for selenium operations, and DEFAULT_TIMEOUT as the selenium-client http read timeout
        browser
      rescue Exception => e
        end_session browser
        raise
      end
    end

    def handle_timeout
      begin
        yield
      rescue Selenium::CommandError => e
        if e.message =~ /Timed out after/
          Log::warn "#{e.class} #{Util::strip_newlines e.message}"
          Log::warn "selenium timed out, attempting to continue operation"
        else
          raise
        end
      end
    end

    def get_page_source( browser )
      browser.get_html_source
    end

    def open_page( browser, relative_path  = "/" )
      browser.open relative_path
    end

    def on( browser, expr )
      browser.get_eval "this.browserbot.getUserWindow().#{expr};"
    end

    def highlight_ads( browser )
      Log::debug "highlighting ads", "selenium"
      on browser, "adbot.highlight_ads()"
    end

    def select_window( browser, window_name )
      # safer than browser.open_window
      # http://jira.openqa.org/browse/SEL-339
      browser.open_window "", window_name
      browser.select_window window_name
    end

    def get_link_target_location( browser, link_url )
      window_name = "link-url-window#{Util::md5 link_url}"
      browser.open_window link_url, window_name
      select_window browser, window_name
      handle_timeout { browser.wait_for_page_to_load MINI_PAGE_TIMEOUT }
      l = browser.location
      if l == "about:blank"
        Log::info "location was about:blank, waiting longer..."
        handle_timeout { browser.wait_for_page_to_load MINI_PAGE_TIMEOUT }
        l = browser.location
      end
      l.gsub! /%2F/i, "/" # easiest for everyone if forward slashes are literal
      Log::info "link url (#{link_url}) had location::: #{l}"
      l
    end

    def include_browser_util( browser )
      Log::debug "injecting jquery", "selenium"
      browser.run_script( JQUERY_SCRIPT )
      Log::debug "done injecting jquery", "selenium"
      Log::debug "injecting adbot jquery", "selenium"
      browser.run_script( ADBOT_JQUERY_SCRIPT )
      Log::debug "done injecting adbot jquery", "selenium"
      Log::debug "injecting browser util", "selenium"
      browser.run_script( BROWSER_UTIL_SCRIPT )
      Log::debug "done injecting browser util", "selenium"
    end

    def page_width( browser )
      Log::debug "get page_width", "selenium"
      (on browser, "adbot.page_width").to_f
    end

    def page_height( browser )
      Log::debug "get page_height", "selenium"
      (on browser, "adbot.page_height").to_f
    end

    def page_title( browser )
      Log::debug "get title", "selenium"
      browser.title
    end

    def get_ad_frames( browser )
      frame_names = on browser, "adbot.frame_names"
      Log::debug "frame names: #{frame_names}"
      frame_names.split ","
    end

    def get_ads_in_current_frame( browser, total_ads_found )
      Log::debug "entering get_ads_in_current_frame", "selenium"
      on browser, "ADBOTjQuery( this.browserbot.getUserWindow().adbot.process_ads )"
      
      ads = []
      on browser, "adbot.ad_iterator()"
      while( true )
        raise "ad limit reached (#{total_ads_found})" unless total_ads_found < MAX_ADS
        on browser, "adbot.next_ad()"
        break unless (on browser, "adbot.is_next_ad") == "true"
        total_ads_found += 1
        
        ad = OpenStruct.new
        ads << ad

        ad.link_url = on browser, "adbot.current_ad.link_url"
        if ad.link_url =~ /SCRAPEME/
          Log::debug "SCRAPME: trying to scrape from #{ad.link_url}"
          ad.link_url = (ad.link_url.scan /clicktag.*?(http.*?)(;|'|")/i)[0][0] rescue ""
          ad.link_url.sub! /^http%3A/i, "http:"
          ad.link_url.sub! /^http:%2F/i, "http:/"
          ad.link_url.sub! /^http:\/%2F/i, "http://"
          ad.link_url.sub! /%2F/i, "/"
          Log::debug "SCRAPED: #{ad.link_url}"
        end
        ad.link_url = "" if ad.link_url =~ /\s/ # naively don't allow URIs with whitespace. don't use URI.parse because some adnetworks use invalid URIs
        ad.link_url = "" if ad.link_url.length < 10 # naively don't allow short link_urls

        ad.element_type = on browser, "adbot.current_ad.element_type"
        ad.format = on browser, "adbot.current_ad.format"
        #ad.screenshot_left = (on browser, "adbot.current_ad.screenshot_left").to_f
        #ad.screenshot_top = (on browser, "adbot.current_ad.screenshot_top").to_f
        ad.screenshot_width = (on browser, "adbot.current_ad.screenshot_width").to_f
        ad.screenshot_height = (on browser, "adbot.current_ad.screenshot_height").to_f
        
        Log::info "found a next ad in browser:"
        Log::info ad
      end

      on browser, "adbot.highlight_ads()"
      
      Log::debug "exiting get_ads_in_current_frame", "selenium"
      ads
    end

    def get_ads( browser, total_ads_found = 0, frame_depth = 1 )
      Log::debug "entering get_ads (total ads found #{total_ads_found}, frame depth #{frame_depth})", "selenium"
      raise "frame depth limit reached (#{frame_depth})" unless frame_depth < MAX_FRAME_DEPTH
      ads = get_ads_in_current_frame browser, total_ads_found
      (get_ad_frames browser).each do |frame|
        Log::debug "entering frame #{frame}", "selenium"
        browser.select_frame frame
        include_browser_util browser
        on browser, "ADBOTjQuery('a,iframe,object,embed').addClass(this.browserbot.getUserWindow().adbot.ad_class)"
        ads.concat(get_ads browser, total_ads_found, frame_depth + 1 )
        total_ads_found = ads.size
        browser.select_frame "relative=up"
        Log::debug "exited frame #{frame}", "selenium"
      end
      highlight_ads browser
      Log::debug "exiting get_ads (total ads found #{total_ads_found}, frame depth #{frame_depth})", "selenium"
      ads
    end

    def page_screenshot( browser )
      browser.capture_entire_page_screenshot_to_string("") rescue nil
    end
  end
end
