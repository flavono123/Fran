# frozen_string_literal: true

require 'byebug'
Dir['app/crawlers/*.rb'].each { |file| require_relative file }
# testing
puts CgvCrawler.new.crawl_cinematalk_movies
CgvCrawler.new.crawl_time_table('공기인형')
