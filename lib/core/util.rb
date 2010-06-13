require 'digest/md5'

def md5( o )
  Digest::MD5.hexdigest(o)
end

module Util
  def self.here( string )
    File.expand_path(File.join(File.dirname(caller[0].split(":")[0]), string))
  end
end

