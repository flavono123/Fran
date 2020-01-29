# frozen_string_literal: true

require 'selenium-webdriver'
require 'retriable'

require_relative '../parsers/cgv_parser'

class CgvCrawler
  def initialize
    @driver = Selenium::WebDriver.for :chrome
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

    btn_theaters = parse(:theaters, multiple: true)
    btn_theaters.each do |btn_theater| # XXX: O(N^2) 😱
      click(btn_theater)
      btn_available_dates = parse(:available_dates, multiple: true)
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
    btn_arthouse = parse(:art_house)
    click(btn_arthouse)

    #  and '시네마톡'
    btn_cinematalk = parse(:cinematalk)
    click(btn_cinematalk)
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
