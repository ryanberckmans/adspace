require 'set'

module AdBot

  class << self
    
    private
    
    def valid( entry )
      return false if entry.lstrip.length < 1
      return false if entry =~ /\#/
      true
    end
    
    public
    
    def get_scans( scan_file )
      scans = Set.new
      File.foreach( scan_file ) { |scan| scans.add( scan.chomp ) if valid(scan) }
      scans.to_a.sort
    end
  end
end
