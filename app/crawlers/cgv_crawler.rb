# frozen_string_literal: true

require 'selenium-webdriver'
require 'retriable'

require_relative '../parsers/cgv_parser'

class CgvCrawler
  def initialize
    @driver = Selenium::WebDriver.for(:chrome)
    @wait = Selenium::WebDriver::Wait.new(timeout: 10)
    @parser = CgvParser.new(driver, wait)
  end

  URL = 'http://ticket.cgv.co.kr/Reservation/Reservation.aspx'

  def crawl_cinematalk_movies
    display_cinematalk_movies

    wait.until do
      !parse(:cinematalk_movies, multiple: true).empty?
    end
    parse(:cinematalk_movies, multiple: true).map { |li| li.text.strip }
  end

  def crawl_time_table(name)
    display_cinematalk_movies

    click(parse_movie(name))

    click(parse(:cinematalk_movie_popup))

    click(parse(:seoul))

    parse(:theaters, multiple: true).each do |theater| # XXX: O(N^2) 😱
      click(theater)
      parse(:available_dates, multiple: true).each do |available_date|
        click(available_date)
        puts parse_time_table
      end
    end
  end

  private

  attr_reader :driver, :wait, :parser

  def display_cinematalk_movies
    driver.navigate.to(URL)

    click(parse(:arthouse))

    click(parse(:cinematalk))
  end

  def parse(element, multiple: false)
    parser.parse(element, multiple: multiple)
  end

  def parse_time_table
    parser.parse_time_table
  end

  def parse_movie(name)
    parser.parse_movie(name)
  end

  def click(element)
    Retriable.retriable(
      tries: 5,
      on: [Selenium::WebDriver::Error::ElementClickInterceptedError]
    ) do
      wait.until { element }.click
    end
  end
end
