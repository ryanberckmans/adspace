require "rubygems"
require "selenium/client"

def getPageSource( url )
  begin
    @browser = Selenium::Client::Driver.new \
    :host => "localhost",
    :port => 4444,
    :browser => "*firefox",
    :url => url,
    :timeout_in_second => 60
    
    @browser.start_new_browser_session
    @browser.open "/"
    @browser.get_html_source
  ensure
    @browser.close_current_browser_session
  end
end



