require "ostruct"
require "core/util.rb"

module Adbot
  class << self
    private

    PARSE_REGEX =  /(<\s*?\/\s*?iframe\s*?>)|(<\s*?\/\s*?noscript\s*?>)|(<\s*?\/\s*?div\s*?>)|(<\s*?div.*?>)|(<\s*?noscript.*?>)|(<\s*?iframe.*?src="(.*?)".*?>)|(<\s*?a.*?href="(.*?)".*?>)(.*?)<\s*?\/\s*?a\s*?>/i

    ADSERVERS = {
      lambda { |link_url, domain| domain =~ /atdmt/i } => "atdmt",
      lambda { |link_url, domain| domain =~ /yieldmanager/i } => "yieldmanager",
      lambda { |link_url, domain| domain =~ /revenuewire/i } => "revenuewire",
      lambda { |link_url, domain| domain =~ /metanetwork/i } => "metanetwork",
      lambda { |link_url, domain| domain =~ /fastclick/i } => "fastclick",
      lambda { |link_url, domain| domain =~ /commindo-media/i } => "commindo-media.de",
      lambda { |link_url, domain| domain =~ /doubleclick/i } => "google doubleclick",
      lambda { |link_url, domain| domain =~ /adtech/i } => "adtech",
      lambda { |link_url, domain| domain =~ /247realmedia/i } => "247realmedia",
      lambda { |link_url, domain| domain =~ /servedbyadbutler/i } => "adbutler",
      lambda { |link_url, domain| domain =~ /spinbox/i } => "spinbox",
      lambda { |link_url, domain| domain =~ /google/i and link_url =~ /adsense/i } => "google adsense",
    }

    class LogicalAd < Exception
      def initialize( logical_ad )
        @logical_ad = logical_ad
      end

      def logical_ad
        @logical_ad
      end
    end

    def iframe_open( match )
      if match[6]
        raise unless match[6] =~ /<\s*?iframe.*?src="(.*?)".*?>/i and match[7] # sanity
        iframe_src = match[7]
        yield iframe_src
      end
    end

    def iframe_close( match )
      if match[1]
        raise unless match[1] =~ /<\s*?\/\s*?iframe\s*?>/i # sanity
        yield
      end
    end

    def div_open( match )
      if match[4]
        raise unless match[4] =~ /<\s*?div.*?>/i # sanity
        yield
      end
    end

    def div_close( match )
      if match[3]
        raise unless match[3] =~ /<\s*?\/\s*?div\s*?>/i # sanity
        yield
      end
    end

    def noscript_open( match )
      if match[5]
        raise unless match[5] =~ /<\s*?noscript.*?>/i # sanity
        yield
      end
    end

    def noscript_close( match )
      if match[2]
        raise unless match[2] =~ /<\s*?\/\s*?noscript\s*?>/i # sanity
        yield
      end
    end

    def link( match )
      if match[8]
        raise unless match[8] =~ /<\s*?a.*?href="(.*?)".*?>/i and match[9] and match[10] #sanity
        link_url = match[9]
        inner_html = match[10]
        yield( link_url, inner_html )
      end
    end

    def is_ad( link_url )
      u = Util::decompose_url link_url
      return unless u
      domain = u.domain if u
      path   = u.path if u
      u = nil # not intended to be used again

      ad = nil

      ADSERVERS.each_key do |is_this_adserver|
        if is_this_adserver[ link_url, domain ]
          ad = OpenStruct.new
          ad.adserver = ADSERVERS[ is_this_adserver ]
          ad.link_url = link_url
          break
        end
      end
      
      ad
    end

    def parse_html( html )
      while true do
        html =~ PARSE_REGEX
        break unless $~
        match = $~

        remaining_html = $'.dup

        iframe_open match do |iframe_src|
          next unless is_ad( iframe_src )
          logical_ad = []

          begin
            remaining_html = parse_html remaining_html do |ad|
              logical_ad << ad  # group all ads in the same advertisement iframe into the same logical_ad
            end
          rescue LogicalAd => e
            logical_ad += e.logical_ad  # group all logical_ads in an advertisement iframe into the same logical_ad
            e.resume
          end

          Util::resumption_exception LogicalAd.new( logical_ad ) if logical_ad.length > 0
        end

        iframe_close match do
          return remaining_html
        end
        
        div_open match do
          logical_ad = []
          remaining_html = parse_html $'.dup do |ad|
            logical_ad << ad
          end
          Util::resumption_exception LogicalAd.new( logical_ad ) if logical_ad.length > 0
        end

        div_close match do
          return remaining_html
        end

        noscript_open match do
          begin
            remaining_html = parse_html remaining_html do |ad|
              # discard ads found inside noscript tags
            end
          rescue LogicalAd => e
            # discard logical ads found inside noscript tags
            e.resume
          end
        end

        noscript_close match do
          return remaining_html
        end

        link match do |link_url, inner_html|
          if ad = is_ad( link_url )
            ad.inner_html = inner_html
            yield ad
          end
        end

        html = remaining_html
      end # while true
    end # parse_html 

    def flatten_logical_ads( ads )
      flattened = []
      ads.each do |logical_ad|
        next unless logical_ad.length > 0
        flattened << logical_ad[0] # flatten logical ads by using only first ad in group
      end
      ads.replace flattened
    end
    
    public
    def find_ads( html )
      ads = []
      begin
        parse_html( html ) { |ad| ads << [ad] }  # advertisements not wrapped in a div are considered their own logical_ad
      rescue LogicalAd => e
        ads << e.logical_ad
        e.resume
      end
      flatten_logical_ads ads
      ads
    end
  end
end
