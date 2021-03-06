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

  def self.strip_newlines( string )
    string.gsub /\r?\n/, ", "
  end

  def self.init_quantcast
    $quantcast_ranks = {}
    $quantcast_order = []
    quantcast_top_million = File.read( here("../../data/quantcast-top-million.txt") )
    quantcast_top_million.gsub(/^(\d+)\t(.*)$/) { |m|
      $quantcast_ranks[ $2 ] = $1
      $quantcast_order << $2
      m
    }
  end
  
  def self.quantcast_rank( url_result )
    init_quantcast unless $quantcast_ranks
    
    url_result.quantcast_rank = -1
    result_domain = url_result.domain.sub(/http:\/\//, "")
    $quantcast_ranks.each_pair { |domain,rank|
      if result_domain == domain
        url_result.quantcast_rank = rank
        return
      end
    }
  end

  def self.domain_contains_url(domain, url)
    domain = URI.parse(domain) rescue OpenStruct.new
    uri = URI.parse(url) rescue OpenStruct.new
    return false unless uri.scheme and uri.host
    return false unless domain.scheme and domain.host
    domain = domain.host
    (uri.host[uri.host.length - domain.length, domain.length] == domain) rescue false
  end

  def self.decompose_url(url)
    uri = URI.parse(url) rescue OpenStruct.new
    return unless uri.scheme and uri.host
    uri.path = "/" unless uri.path and uri.path.length > 0
    OpenStruct.new("domain" => "#{uri.scheme}://#{uri.host}",
                   "path" => uri.path)
  end

  def self.uri_safe_parse( original_uri )
    # given a uri in the form scheme://host/path, the code encodes/escapes the path into hex (e.g. %2F), and uses the URI library to correctly parse characters like "|"

    # self.uri_safe_parse assumes original:
    # * is http/https
    # * includes the full scheme:  http://
    # * assumes the host is terminated by a slash, i.e. google.com/ not google.com
    
    # note: lib URI requires host to be terminated by a literal slash, not %2F, i.e. google.com/ parses correctly, google.com%2f does not parse
    host = original_uri.slice /^(https?.*?\/\/.*?)\//i, 1
    path = original_uri.slice /^https?.*?\/\/.*?\/(.*)/i, 1

    return nil unless host and path
    raise unless host + "/" + path == original_uri

    decoded_host = host.gsub /%(..)/ do $1.hex.chr end
    encoded_path = path.gsub /./ do "%#{$&[0].to_s(16)}" end

    uri = URI.parse decoded_host + "/" + encoded_path rescue return nil

    decoded_path = uri.path.gsub /%(..)/ do $1.hex.chr end
    
    OpenStruct.new "host" => uri.host, "path" => decoded_path, "scheme" => uri.scheme
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
