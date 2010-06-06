require 'base64'
require 'set'
require 'core/util.rb'

module Adbot
  class << self
    
    private
    
    def summary( scans_with_match, options )
      puts 
      puts "--------------------------"
      puts "summary:"
      puts " (search performed for #{options.human_client})"
      puts "-------"
      
      scans_with_match.keys.sort.each do |scan|
        puts "  #{scan} advertises on:"
        
        scan_result = scans_with_match[scan]
        
        urls = Set.new
        
        scan_result.matches.each do
          |match|
          urls.add "#{match.url} (adserver #{match.adserver})"
        end
        
        urls.sort.each do
          |url|
          puts "    #{url}"
        end
      end
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
    
    def make_webpage( scans_with_match, options )
      puts
      puts "saving match data to client subdirectory ../client/#{options.human_client}"
      
      make_client_directories options
      
      begin
        File.open("../client/#{options.human_client}/index.html", 'w') do |f|
          
          f.write "<html><head><title>AdChart results for #{options.human_client}</title><link rel=\"stylesheet\" type=\"text/css\" href=\"../web/styles.css\"></head><body>"
          
          f.write "<div id=\"header\"><div class=\"content\"> </div> </div>"
          f.write "<div id=\"container\">"
          
          scans_with_match.keys.sort.each do |scan|
            f.write "<h2>#{scan} advertisements</h2>"
            
            scan_result = scans_with_match[scan]
            
            urls = {}
            
            scan_result.matches.each do |match|
              urls[match.url] = [] unless urls[match.url]
              urls[match.url].push match
            end
            
            urls.each_key do
              |url|
              
              f.write "<div class=\"ad-list\">"
              f.write "<h3>#{url}:</h3>"
              
              unique_inner_html = Set.new
              
              urls[url].each do |match|
                next unless not unique_inner_html.include? match.inner_html
                unique_inner_html.add match.inner_html
                
                f.write "<div class=\"ad-detail\">"
                f.write "  <a href=\"#{match.link_url}\" target=\"_blank\"> #{match.inner_html} </a>"
                f.write "  <p>(#{match.adserver})</p>"
                f.write "</div>"
              end
              f.write "</div>" # ad-list
            end # urls.each_key
          end # each competitor
          
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
    
    def process_matches( scans_with_match, options )
      
      puts "processing matches..." if options.verbose

      if scans_with_match.empty? then
        puts "no matches found"
        return
      end
      
      make_webpage( scans_with_match, options )

      summary( scans_with_match, options )
    end
  end
end 
