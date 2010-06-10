require 'ostruct'
require 'digest/md5'

module Util
  def self.md5( o )
    Digest::MD5.hexdigest(o)
  end

  def self.decompose_url( url )
    url = unescape_html url
    re = /^(.*?\/\/.*?)(\/.*)?$/i
    m = re.match(url)
    return unless m
    OpenStruct.new( { "domain" => m[1], "path" => m[2] } )
  end

  def self.unescape_html(string)
    # from pragmatic
    str = string.dup
    str.gsub!(/&(.*?);/n) do
      match = $1.dup
      case match
      when /\Aamp\z/ni           then '&'
      when /\Aquot\z/ni          then '"'
      when /\Agt\z/ni            then '>'
      when /\Alt\z/ni            then '<'
      when /\A#(\d+)\z/n         then Integer($1).chr
      when /\A#x([0-9a-f]+)\z/ni then $1.hex.chr
      end
    end
    str
  end

  def self.resumption_exception(*args)
    # from internet
    raise *args
  rescue Exception => e
    callcc do |cc|
      scls = class << e; self; end
      scls.send(:define_method, :resume, lambda { cc.call })
      raise
    end
  end

  def self.here( string )
    File.expand_path(File.join(File.dirname(caller[0].split(":")[0]), string))
  end
end
