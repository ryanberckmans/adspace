require 'rubygems'
require 'json/pure'
require 'active_support'
require 'base64'
require 'set'
require 'core/util.rb'

class OpenStruct
  # implement OpenStruct::to_json for temporary file output
  def to_json(*a)
    JSON.generate(marshal_dump())
  end
end

# ActiveSupport requires rubygems >= 1.3.6, zr1 has 1.3.4

# workaround for activesupport vs. json_pure vs. Ruby 1.8 glitch
# source: http://pivotallabs.com/users/alex/blog/articles/1332-monkey-patch-of-the-day-activesupport-vs-json-pure-vs-ruby-1-8
#if JSON.const_defined?(:Pure)
#  class JSON::Pure::Generator::State
#    include ActiveSupport::CoreExtensions::Hash::Except
#  end
#end  

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
        FileUtils.mkdir("../client/no-client")
      rescue Exception => e
      end
    end
    
    def make_webpage( url_results, options )
      puts
      puts "saving match data to client subdirectory ../client/no-client"
      
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
        File.open("../client/no-client/index.html", 'w') do |f|
          
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
              next if unique_inner_html.include? ad.inner_html
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
      
      system "google-chrome ../client/no-client/index.html&"
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

    def output_error( url_result, options )
      begin
        to_write = ""
        endl = "\n"

        to_write += "ERROR SCANNING " + url_result.url + endl
        url_result.html = nil # remove possible spam
        url_result.screenshot = nil # remove possible spam
        to_write += url_result.to_s + endl
        to_write += url_result.exception.backtrace.join(endl) + endl
        to_write += url_result.exception.message + endl
        to_write += "END ERROR" + endl

        file_path = options.output_dir + ".error" # output dir is treated as a file path when using output_tabular
        f = File.open file_path, "a"
        f.write to_write
        puts "wrote error details for #{url_result.url} to #{file_path}" if options.verbose
      rescue Exception => e
        puts e.backtrace
        puts e.message
        puts "failed to write error details to #{options.output_dir}.error for #{url_result.url}"
      ensure
        f.close rescue nil
      end
    end

    def output_tabular( url_result, options )
      begin
        to_write = ""
        tab = "\t"
        prefix =
          url_result.date + tab +
          url_result.url + tab +
          url_result.quantcast_rank + tab +
          url_result.domain + tab +
          url_result.path + tab +
          url_result.title + tab +
          url_result.page_width.to_s + tab +
          url_result.page_height.to_s + tab
        
        if url_result.ads.length > 0
          url_result.ads.each { |ad|
            to_write += prefix +
            ad.format + tab +
            ad.element_type + tab +
            ad.link_url + tab +
            ad.target_location + tab +
            #ad.screenshot_top.to_s + tab +
            #ad.screenshot_left.to_s + tab +
            ad.screenshot_width.to_s + tab +
            ad.screenshot_height.to_s + "\n"
          }
        else
          to_write += prefix + "-1\n"
        end

        file_path = options.output_dir # output dir is treated as a file path when using output_tabular
        f = File.open file_path, "a"
        f.write to_write
        puts "wrote results for #{url_result.url} to #{file_path}" if options.verbose
      rescue Exception => e
        puts e.backtrace
        puts e.message
        puts "failed to write to #{options.output_dir} for #{url_result.url}"
      ensure
        f.close rescue nil
      end
    end

    def output_json( url_result, options ) 
      begin
        file_path = options.output_dir + url_result.url.split("//")[1].gsub("/", ".") + ".txt"
        f = File.open file_path, "a"
        to_write = "BEGIN_SCAN\n"
        to_write += JSON.generate(url_result)
        to_write += "\nEND_SCAN\n"
        f.write to_write
        puts "wrote url_result for #{url_result.url} to #{file_path}" if options.verbose
      rescue Exception => e
        puts e.backtrace
        puts e.message
        puts "failed to write json output file for #{url_result.url}"
      ensure
        f.close
      end
    end
    
  end # class << self
end 
