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

    MINI_PAGE_TIMEOUT = 20 # seconds
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
      rescue Selenium::CommandError => e
        if e.message =~ /Timed out after/
          puts e.message
          puts "selenium timed out, attempting to continue operation"
        else
          raise
        end
      end
    end

    def get_page_source( browser )
      browser.get_html_source
    end

    def open_page( browser, relative_path  = "/" )
      handle_timeout { browser.open relative_path }
    end

    def on( browser, expr )
      browser.get_eval "this.browserbot.getUserWindow().adbot.#{expr};"
    end

    def highlight_ads( browser )
      on browser, "highlight_ads()"
    end

    def get_link_target_location( browser, link_url )
      browser.open_window link_url, "link-url-window"
      browser.select_window "link-url-window"
      handle_timeout { browser.wait_for_page_to_load MINI_PAGE_TIMEOUT }
      location = browser.location
      browser.select_window nil # reselect main window
      location
    end

    def include_browser_util( browser )
      browser.run_script( JQUERY_SCRIPT )
      browser.run_script( ADBOT_JQUERY_SCRIPT )
      browser.run_script( BROWSER_UTIL_SCRIPT )
    end

    def page_width( browser )
      on browser, "page_width"
    end

    def page_height( browser )
      on browser, "page_height"
    end

    def page_title( browser )
      browser.title
    end

    def scan_date( browser )
      on browser, "date"
    end

    def get_ads( browser )
      ads = []
      
      on browser, "ad_iterator()"

      while( true )
        on browser, "next_ad()"
        break unless (on browser, "is_next_ad") == "true"

        ad = OpenStruct.new
        ads << ad

        ad.link_url = URI.parse(Util::unescape_html((on browser, "current_ad.link_url"))).to_s rescue nil
        ad.type = on browser, "current_ad.type"
        ad.screenshot_left = (on browser, "current_ad.screenshot_left").to_f
        ad.screenshot_top = (on browser, "current_ad.screenshot_top").to_f
        ad.screenshot_width = (on browser, "current_ad.screenshot_width").to_f
        ad.screenshot_height = (on browser, "current_ad.screenshot_height").to_f
        
        puts "found a next ad in browser:"
        puts ad
      end

      ads
    end

    def page_screenshot( browser )
      browser.capture_entire_page_screenshot_to_string("") rescue nil
    end
  end
end
