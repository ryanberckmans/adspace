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
        Log::error Util::strip_newlines e.message
        Log::error "#{e.class} failed to write error details to #{options.output_dir}.error for #{url_result.url}"
      ensure
        f.close rescue nil
      end
    end

    def output_tabular_headers( file_path )
      begin
        headers = %w[ scan_time scan_unix_time scan_id scan_created_at scan_updated_at scan_completed? domain path quantcast_rank page_width page_height page_title scan_failed? fail_message fail_backtrace ads_found? ad_id ad_link_url ad_target_url ad_screenshot_width ad_screenshot_height ad_format ]
        tab = "\t"
        to_write = ""
        headers.each do |header| to_write += header + tab end
        to_write += "\n"
        f = File.open file_path, "a"
        f.write to_write
        Log::info "wrote tabular headers to #{file_path}"
      rescue Exception => e
        Log::error e.backtrace.join "\t"
        Log::error Util::strip_newlines e.message
        Log::error "#{e.class} failed to write to #{options.output_dir} for #{scan.url}"
      ensure
        f.close rescue nil
      end
    end

    def output_tabular( scan, options )
      output_tabular_headers options.output_dir if not File.exists? options.output_dir
      begin
        to_write = ""
        tab = "\t"
        endl = "\n"
        prefix =
          scan.scan_time.to_s + tab +
          scan.scan_time.to_f.to_s + tab +
          scan.id.to_s + tab +
          scan.created_at.to_f.to_s + tab +
          scan.updated_at.to_f.to_s + tab +
          (scan.scan_completed ? 1.to_s : 0.to_s) + tab +
          scan.domain.url + tab +
          scan.path + tab +
          scan.domain.quantcast_rank.to_s + tab +
          scan.page_width.to_s + tab +
          scan.page_height.to_s + tab + 
          scan.title.to_s + tab

        if scan.scan_fail
          prefix += 1.to_s + tab +
            scan.scan_fail.message + tab +
            scan.scan_fail.backtrace + tab
        else
          prefix += 0.to_s + tab + tab + tab
        end

        if scan.ads.length > 0
          prefix += 1.to_s + tab
        else
          prefix += 0.to_s + tab
        end

        if scan.ads.length > 0
          scan.ads.each do |ad|
            to_write += prefix + ad.id.to_s + tab +
              ad.link_url + tab +
              ad.target_url + tab +
              ad.screenshot_width.to_s + tab +
              ad.screenshot_height.to_s + tab +
              ad.format + tab + endl
          end
        else
          to_write += prefix + tab + tab + tab + tab + tab + tab + endl
        end

        file_path = options.output_dir # output dir is treated as a file path when using output_tabular
        f = File.open file_path, "a"
        f.write to_write
        Log::info "wrote results for scan #{scan.id} to #{file_path}"
      rescue Exception => e
        Log::error e.backtrace.join "\t"
        Log::error Util::strip_newlines e.message
        Log::error "#{e.class} failed to write to #{options.output_dir} for scan #{scan.id}"
      ensure
        f.close rescue nil
      end
    end

  end # class << self
end 
