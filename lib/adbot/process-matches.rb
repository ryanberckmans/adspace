require 'base64'
require 'set'
require 'core/util.rb'

module Adbot
  class << self
    
    private

    def summary_text( url_results )
      urls = Set.new
      target_locations = Set.new
      results = 0
      ads = 0

      url_results.each do |url_result|
        next if url_result.error_scanning
        urls.add url_result.domain
        results += 1
        ads += url_result.ads.length
        url_result.ads.each { |ad| target_locations.add ad.target_location if ad.target_location }
      end

      "AdChart acquired intelligence on #{ads} advertisements leading to #{target_locations.length} target locations on #{results} passes over #{urls.length} urls"
    end
    
    def summary( url_results, options )
      puts summary_text url_results
    end
    
    def make_client_directories( options )
      begin
        FileUtils.mkdir("../client")
      rescue Exception => e
      end
      
      begin
        FileUtils.mkdir("../client/#{options.human_client}")
      rescue Exception => e
      end
    end
    
    def make_webpage( url_results, options )
      puts
      puts "saving match data to client subdirectory ../client/#{options.human_client}"
      
      make_client_directories options

      results_by_target_domain = {}
      
      url_results.each do |url_result|
        next if url_result.error_scanning or not url_result.ads
        url_result.ads.each do |ad|
          next unless ad.target_location
          u = Util::decompose_url ad.target_location
          next unless u
          target_domain = u.domain
          u = nil # not intended to be used agan

          ad.url = url_result.url
          
          results_by_target_domain[target_domain] ||= []
          results_by_target_domain[target_domain].push ad
        end
      end

      begin
        File.open("../client/#{options.human_client}/index.html", 'w') do |f|
          
          f.write "<html><head><title>AdChart</title><link rel=\"stylesheet\" type=\"text/css\" href=\"../web/styles.css\"></head><body>"
          
          f.write "<div id=\"header\"><div class=\"content\"> </div> </div>"
          f.write "<div id=\"container\">"

          f.write "<h2>#{summary_text url_results}</h2>"

          f.write "<div class=\"ad-list\">"

          results_by_target_domain.each_key do |target_domain|
            f.write "<div class=\"ad-detail-container\">"
            f.write "<h3>advertisements by #{target_domain}:</h3>"

            unique_inner_html = Set.new
            results_by_target_domain[target_domain].each do |ad|
              next unless not unique_inner_html.include? ad.inner_html
              unique_inner_html.add ad.inner_html
              
              f.write "<div class=\"ad-detail\">"
              f.write "  <a href=\"#{ad.target_location}\" target=\"_blank\"> #{ad.inner_html} </a>"
              f.write "  <p>on page <b>#{ad.url}</b>, served by #{ad.adserver}</p>"
              f.write "</div>"
            end

            f.write "</div>"
          end

          f.write "</div>" # ad-list
          
          f.write "</div>" # container
          f.write "</body></html>"
        end
      rescue Exception => e
        puts "error writing to file"
        raise
      end
      
      system "google-chrome ../client/#{options.human_client}/index.html&"
    end

    public
    
    def process_matches( url_results, options )

      puts "processing matches..."

      begin
        make_webpage( url_results, options )
        summary( url_results, options )
      rescue Exception => e
        puts e.backtrace
        puts e.message
        puts "error processing matches"
      end
    end
  end
end 
