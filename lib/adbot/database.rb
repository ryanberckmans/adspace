
module Adbot
  def self.save_url( url_result, options )
    if url_result.html
      begin
        File.open("/tmp/latest.html", "w") do |f|
          f.write url_result.html
        end
        puts "wrote #{url_result.url} html to /tmp/latest.html" if options.verbose
      rescue Exception => e
        puts "failed to write html to /tmp/latest.html"
      end
    end

    puts "saving url result to database" if options.verbose

    s = Scan.from_open_struct url_result
    s.save
  end
end
