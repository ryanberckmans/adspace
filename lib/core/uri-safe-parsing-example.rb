require 'uri'

# given a uri in the form scheme://host/path, the code encodes/escapes the path into hex (e.g. %2F), and uses the URI library to correctly parse the pipe character "|"

# the following code assumes the uri:
# * is http/https
# * includes the full scheme:  http://
# * assumes the host is terminated by a slash, i.e. google.com/ not google.com

# note: lib URI requires host to be terminated by a literal slash, not %2F, i.e. google.com/ parses correctly, google.com%2f does not parse

original = "https://mail.google.com/mail/?shva=1#pipe|mbox"
host = original.slice /^(http.*?\/\/.*?)\//i, 1
path = original.slice /^http.*?\/\/.*?\/(.*)/i, 1

encoded_path = path.gsub /./ do "%#{$&[0].to_s(16)}" end

uri = URI.parse host + "/" + encoded_path

decoded_uri_path = uri.path.gsub /%(..)/ do $1.hex.chr end

puts "orig: #{original}"
puts "host: #{host}"
puts "path: #{path}"
puts "code: #{encoded_path}"
puts "using URI lib:"
puts "uri : #{uri.scheme}"
puts "uri : #{uri.host}"
puts "uri : #{uri.path}"
puts "and the uri.path translated back into ascii is: #{decoded_uri_path}"
puts "---"
puts "as expected, lib URI throws an exception when parsing the literal URI (#{original}):"
URI.parse original
