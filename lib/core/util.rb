require 'ostruct'
require 'digest/md5'
require 'uri'

module Util
  def self.md5( o )
    Digest::MD5.hexdigest(o)
  end

  def self.here( string )
    File.expand_path(File.join(File.dirname(caller[0].split(":")[0]), string))
  end


  def self.init_quantcast
    $quantcast_ranks = {}
    quantcast_top_million = File.read( here("../../data/quantcast-top-million.txt") )
    quantcast_top_million.gsub(/^(\d+)\t(.*)$/) { |m|
      $quantcast_ranks[ $2 ] = $1
      m
    }
  end
  
  def self.quantcast_rank( url_result )
    init_quantcast unless $quantcast_ranks
    
    url_result.quantcast_rank = -1
    result_domain = url_result.domain.sub(/http:\/\//, "")
    $quantcast_ranks.each_pair { |domain,rank|
      if result_domain == domain
        puts result_domain
        puts domain
        puts rank
        url_result.quantcast_rank = rank
        return
      end
    }
  end

  def self.decompose_url(url)
    uri = URI.parse(url) rescue OpenStruct.new
    return unless uri.scheme and uri.host
    OpenStruct.new("domain" => "#{uri.scheme}://#{uri.host}",
                   "path" => uri.path)
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

end
