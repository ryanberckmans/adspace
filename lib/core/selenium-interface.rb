require "rubygems"
require "selenium/client"

module SeleniumInterface
  class << self

    def close( browser )
      browser.close_current_browser_session
    end

    def browser( url, selenium_host )
      begin
        browser = Selenium::Client::Driver.new \
        :host => selenium_host,
        :port => 4444,
        :browser => "*firefox",
        :url => url,
        :timeout_in_second => 60

        browser.start_new_browser_session
        browser
      rescue Exception => e
        close( browser ) 
        raise
      end
    end

    def get_page_source( browser, relative_path  = "/" )
      begin
        browser.open relative_path
        browser.get_html_source
      rescue Exception => e
        close( browser )
      end
    end

    def page_screenshot( browser )
      begin
        screenshot = browser.capture_entire_page_screenshot_to_string("")
        screenshot
      rescue Exception => e
        close( browser )
      end
    end
  end
end
