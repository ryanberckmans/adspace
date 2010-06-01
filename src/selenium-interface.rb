require "rubygems"
require "selenium/client"

def close( browser )
  browser.close_current_browser_session
end

def browser( url, seleniumHost )
  begin
    browser = Selenium::Client::Driver.new \
    :host => seleniumHost,
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

def getPageSource( browser, relativePath  = "/" )
  begin
    browser.open relativePath
    browser.get_html_source
  rescue Exception => e
    close( browser )
  end
end

def pageScreenshot( browser )
  begin
    screenshot = browser.capture_entire_page_screenshot_to_string("")
    screenshot
  rescue Exception => e
    close( browser )
  end
end

