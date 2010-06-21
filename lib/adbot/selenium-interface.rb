require "rubygems"
require "selenium/client"
require "core/util.rb"

module SeleniumInterface

  INCLUDE_JQUERY_SCRIPT_FILE = "include-jquery.js"
  BROWSER_UTIL_SCRIPT_FILE = "browser-util.js"

  INCLUDE_JQUERY_SCRIPT = File.read( Util.here( INCLUDE_JQUERY_SCRIPT_FILE ) )

  BROWSER_UTIL_SCRIPT = File.read( Util.here( BROWSER_UTIL_SCRIPT_FILE ) )

  class << self

    MINI_PAGE_TIMEOUT = 10 # seconds
    PAGE_TIMEOUT = 60 # seconds
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
          puts "selenium timed out, continuing operation with available data"
        else
          raise
        end
      end
    end

    def get_page_source( browser, relative_path  = "/" )
      handle_timeout { browser.open relative_path }
      browser.get_html_source
    end

    def get_link_target_location( browser, link_url )
      browser.open_window( link_url, "link-url-window" )
      browser.select_window "link-url-window"
      handle_timeout { browser.wait_for_page_to_load MINI_PAGE_TIMEOUT }
      browser.select_window( nil ) # reselect main window
      browser.location
    end

    def include_jquery( browser )
      browser.run_script( INCLUDE_JQUERY_SCRIPT )
    end

    def include_browser_util( browser )
      include_jquery browser
      browser.run_script( BROWSER_UTIL_SCRIPT )
    end

    def ad_screenshot_info( browser, jquery_selector )
      browser.get_eval("this.browserbot.getUserWindow().adbot.set_ad_screenshot_info(\"#{jquery_selector}\");")
      info = OpenStruct.new
      info.left = browser.get_eval("this.browserbot.getUserWindow().adbot.ad_screenshot.left");
      info.top = browser.get_eval("this.browserbot.getUserWindow().adbot.ad_screenshot.top");
      info.width = browser.get_eval("this.browserbot.getUserWindow().adbot.ad_screenshot.width");
      info.height = browser.get_eval("this.browserbot.getUserWindow().adbot.ad_screenshot.height");
      info
    end

    def page_screenshot( browser )
      browser.capture_entire_page_screenshot_to_string("") rescue nil
    end
  end
end
