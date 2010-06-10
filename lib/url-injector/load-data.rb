
module UrlInjector
  class << self
    private
    def valid( entry )
      return false if entry.lstrip.length < 1
      return false if entry =~ /\#/
      true
    end

    public
    def get_urls( url_file )
      urls = []
      File.foreach( url_file ) { |url| urls.push( url.chomp ) if valid(url) }
      urls
    end
  end
end
