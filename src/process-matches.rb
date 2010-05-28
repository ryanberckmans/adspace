require 'set'

def _summary( matches )
  puts 
  puts "--------------------------"
  puts "summary:"
  puts "-------"
  
  matches.keys.sort.each do |key|
    puts "  #{key} advertises on:"

    urls = Set.new
    
    matches[key].each do
      |match|
      urls.add match.url
    end
    
    urls.each do
      |url|
      puts "    #{url}"
    end
  end
end


def processMatches( matches )

  if matches.empty? then
    puts "no matches found"
    return
  end

  puts
  puts "(unimplemented) saving match data to subdirectory ... "
  
  _summary matches
  
  # File.open("./#{match.scan}.html", 'a') { |f| f.write(match.html) }
end
