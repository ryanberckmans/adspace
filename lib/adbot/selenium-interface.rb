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

  class << self

    MINI_PAGE_TIMEOUT = 30 # seconds
    PAGE_TIMEOUT = 120 # seconds
    DEFAULT_TIMEOUT = 300 # seconds, also used as http read timeout for selenium server connection

    MILLIS_IN_SECOND = 1000
    def in_milliseconds( t )
      return t * MILLIS_IN_SECOND
    end

    def end_session( browser )
      begin
        browser.close_current_browser_session if browser
      rescue Exception => e
        puts e.message
        puts "error ending browser session"
      end
    end

    def browser( url, selenium_host, selenium_port )
      begin
        browser = Selenium::Client::Driver.new \
        :host => selenium_host,
        :port => selenium_port,
        :browser => "*firefox",
        :url => url,
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
        $timed_out = false
      rescue Selenium::CommandError => e
        if e.message =~ /Timed out after/
          puts e.message
          puts "selenium timed out, attempting to continue operation"
          $timed_out = true
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
      on browser, "adbot.highlight_ads()"
    end

    def select_window( browser, window_name )
      # safer than browser.open_window
      # http://jira.openqa.org/browse/SEL-339
      browser.open_window "", window_name
      browser.select_window window_name
    end

    def get_link_target_location( browser, link_url )
      sleep 2 # don't hit selenium so hard
      window_name = "link-url-window"
      browser.open_window link_url, window_name
      select_window browser, window_name
      handle_timeout { browser.wait_for_page_to_load MINI_PAGE_TIMEOUT }
      handle_timeout { browser.wait_for_page_to_load MINI_PAGE_TIMEOUT } if $timed_out # re-try once
      l = browser.location
      puts "link url (#{link_url}) had location::: #{l}"
      l
    end

    def include_browser_util( browser )
      browser.run_script( JQUERY_SCRIPT )
      browser.run_script( ADBOT_JQUERY_SCRIPT )
      browser.run_script( BROWSER_UTIL_SCRIPT )
    end

    def page_width( browser )
      (on browser, "adbot.page_width").to_f
    end

    def page_height( browser )
      (on browser, "adbot.page_height").to_f
    end

    def page_title( browser )
      browser.title
    end

    def get_ad_frames( browser )
      on browser, "adbot.collect_frames()"
      frame_names = on browser, "adbot.frame_names"
      puts "frame names: #{frame_names}"
      frame_names.split ","
    end

    def get_ads_in_current_frame( browser )
      on browser, "ADBOTjQuery( this.browserbot.getUserWindow().adbot.process_ads );"
      
      ads = []
      on browser, "adbot.ad_iterator()"
      while( true )
        on browser, "adbot.next_ad()"
        break unless (on browser, "adbot.is_next_ad") == "true"

        ad = OpenStruct.new
        ads << ad

        ad.link_url = on browser, "adbot.current_ad.link_url"
        if ad.link_url =~ /SCRAPEME/
          puts "SCRAPME: trying to scrape from #{ad.link_url}"
          ad.link_url = (ad.link_url.scan /clicktag.*?(http.*?)(;|'|")/i)[0][0] rescue ""
          puts "scraped: #{ad.link_url}"
        end
        ad.link_url = Util::unesacpe_html ad.link_url rescue ad.link_url
        ad.link_url.gsub!(/%([0-9a-f][0-9a-f])/i) { $1.hex.chr }
        ad.link_url = "" if ad.link_url =~ /\s/ # naively don't allow URIs with whitespace. don't use URI.parse because some adnetworks use invalid URIs
        ad.link_url = "" if ad.link_url.length < 10 # naively don't allow short link_urls
        ad.link_url = "" if ad.link_url =~ /link-url-not-supported/ # this is what browser-util defaults to

        ad.element_type = on browser, "adbot.current_ad.type"
        #ad.screenshot_left = (on browser, "adbot.current_ad.screenshot_left").to_f
        #ad.screenshot_top = (on browser, "adbot.current_ad.screenshot_top").to_f
        #ad.screenshot_width = (on browser, "adbot.current_ad.screenshot_width").to_f
        #ad.screenshot_height = (on browser, "adbot.current_ad.screenshot_height").to_f
        
        puts "found a next ad in browser:"
        puts ad
      end
      ads
    end

    def get_ads( browser )
      ads = get_ads_in_current_frame browser
      (get_ad_frames browser).each do |frame|
        puts "entering frame #{frame}"
        browser.select_frame frame
        include_browser_util browser
        on browser, "ADBOTjQuery('a,iframe,object,embed').addClass(this.browserbot.getUserWindow().adbot.ad_class)"
        ads.concat(get_ads browser)
        browser.select_frame "relative=up"
        puts "exited frame #{frame}"
      end
      ads
    end

    def page_screenshot( browser )
      browser.capture_entire_page_screenshot_to_string("") rescue nil
    end
  end
end
