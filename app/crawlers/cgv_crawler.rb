# frozen_string_literal: true

require 'selenium-webdriver'
require 'retriable'

require_relative '../parsers/cgv_parser'

# TODO: rename parser delegate methods; nounize (e.g. remove prefixes `parse_`)
class CgvCrawler
  class NoCinematalkMovies < StandardError; end

  def initialize
    @driver = Selenium::WebDriver.for :chrome
    @wait = Selenium::WebDriver::Wait.new(timeout: 10)
    @parser = CgvParser.new(driver, wait)
  end

  URL = 'http://ticket.cgv.co.kr/Reservation/Reservation.aspx'

  def crawl_cinematalk_movies
    display_cinematalk_movies

    wait.until do
      !parse_cinematalk_movies.empty?
    end
    parse_cinematalk_movies.map { |li| li.text.strip }
  end

  def crawl_time_table(name)
    display_cinematalk_movies

    click(parse_movie(name))

    click(parse_cinematalk_movie_popup)

    click(parse_seoul)

    btn_theaters = parse_theaters
    btn_theaters.each do |btn_theater| # XXX: O(N^2) 😱
      click(btn_theater)
      btn_available_dates = parse_available_dates
      btn_available_dates.each do |btn_available_date|
        click(btn_available_date)
        puts parse_time_table
      end
    end
  end

  private

  attr_reader :driver, :wait, :parser

  def display_cinematalk_movies
    driver.navigate.to(URL)
    # click the button '아트하우스'
    btn_arthouse = parse_art_house
    click(btn_arthouse)

    #  and '시네마톡'
    btn_cinematalk = parse_cinematalk
    click(btn_cinematalk)
  end

  def parse_cinematalk_movies
    parser.parse_cinematalk_movies
  end

  def parse_available_dates
    parser.parse_available_dates
  end

  def parse_time_table
    parser.parse_time_table
  end

  def parse_movie(name)
    parser.parse_movie(name)
  end

  def parse_cinematalk_movie_popup
    parser.parse_cinematalk_movie_popup
  end

  def parse_seoul
    parser.parse_seoul
  end

  def parse_theaters
    parser.pase_theaters
  end

  def parse_art_house
    parser.parse_art_house
  end

  def parse_cinematalk
    parser.parse_cinematalk
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
