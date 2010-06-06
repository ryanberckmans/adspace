
module AWS
  class << self
    def access_key
      key = nil
      File.open("../aws/access-key", 'r')  do |f|
        key = f.gets.chomp
      end
      key
    end
    
    def secret_access_key
      key = nil
      File.open("../aws/secret-access-key", 'r')  do |f|
        key = f.gets.chomp
      end
      key
    end
  end
end
