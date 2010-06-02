require 'digest/md5'

def md5( o )
  Digest::MD5.hexdigest(o)
end
