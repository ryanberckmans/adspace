require 'rubygems'
require 'core/util.rb'

module Adbot
  class << self
    
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
        Log::info "wrote error details for #{url_result.url} to #{file_path}"
      rescue Exception => e
        Log::error e.backtrace.join "\t"
        Log::error e.message
        Log::error "#{e.class} failed to write error details to #{options.output_dir}.error for #{url_result.url}"
      ensure
        f.close rescue nil
      end
    end

    def output_tabular( url_result, options )
      begin
        to_write = ""
        tab = "\t"
        prefix =
          url_result.scan_time.to_s + tab +
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
        Log::info "wrote results for #{url_result.url} to #{file_path}"
      rescue Exception => e
        Log::error e.backtrace.join "\t"
        Log::error e.message
        Log::error "#{e.class} failed to write to #{options.output_dir} for #{url_result.url}"
      ensure
        f.close rescue nil
      end
    end

  end # class << self
end 
