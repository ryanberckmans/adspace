require 'digest/md5'

def md5( o )
  Digest::MD5.hexdigest(o)
end

class File
  def self.here( string )
    File.expand_path(File.join(File.dirname(__FILE__), string))
  end
end

