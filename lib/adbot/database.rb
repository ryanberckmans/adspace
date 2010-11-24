
module Adbot
  def self.save( url_result )
    s = Scan.from_open_struct url_result
    s.scan_completed = true
    raise unless s.save
  end
end
