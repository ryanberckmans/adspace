
module Adbot
  def self.save( url_result, scan_id )
    attrs = Scan.attrs_from_open_struct url_result
    attrs.merge!({:scan_completed => true})
    scan = Scan.find scan_id
    raise "scan #{scan_id} was already completed" if scan.scan_completed
    raise "scan.update_attributes failed" unless scan.update_attributes attrs
  end
end
