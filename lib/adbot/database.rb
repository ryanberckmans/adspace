
module Adbot
  class << self
    def save_url( url_result, options )
      # this is the sole connection point to the webapp/front end
      # to see contents of url_result:
      #  cat lib/adbot/scan.rb | egrep -nC2 "url_result\."

      puts "saving url result to database:"
      s = Scan.from_open_struct url_result
      s.save

      puts url_result if options.verbose
    end
  end
end
