require 'byebug'
Dir['app/crawlers/*.rb'].each {|file| require_relative file}
# testing
CgvCrawler.new.call
