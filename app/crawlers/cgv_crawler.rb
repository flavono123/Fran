# frozen_string_literal: true

require 'selenium-webdriver'
require 'retriable'

require_relative '../parsers/cgv_parser'

class CgvCrawler
  class NoCinematalkMovies < StandardError; end

  def initialize
    @driver = Selenium::WebDriver.for :chrome
    driver.manage.timeouts.page_load = 10
    @wait = Selenium::WebDriver::Wait.new(timeout: 10)
    @parser = CgvParser.new(driver, wait)
  end

  URL = 'http://ticket.cgv.co.kr/Reservation/Reservation.aspx?MOVIE_CD=&MOVIE_'\
  'CD_GROUP=&PLAY_YMD=&THEATER_CD=&PLAY_NUM=&PLAY_START_TM=&AREA_CD=&SCREEN_CD'\
  '=&THIRD_ITEM=#'
  XPATHS = {
    btn_arthouse: "//div[@class='movie-select']/div[@class='tabmenu']/a[contai"\
    "ns(@class, 'menu2')]",
    btn_cinematalk: "//div[@class='tabmenu-selectbox MOVIECOLLAGE']/ul/li/a[co"\
    "ntains(text(), '시네마톡')]",
    cinematalk_movie_list: "//div[@class='movie-list nano']/ul/li",
    btn_cinematalk_in_popup: "//div[@class='selectbox-movie-type checkedBD']/u"\
    "l/li/a[text()='시네마톡']",
    btn_seoul: "//div[@class='theater-area-list']/ul/li/a/span[contains(text(), '서울')]",
    area_list: "//div[@class='theater-area-list']/ul/li/a",
    theater_list: "//div[@class='theater-area-list']/ul/li[@class='selected']/"\
    "div[@class='area_theater_list nano']/ul/li[not(@class='dimmed')]/a"
  }.freeze

  def crawl_cinematalk_movies
    display_cinematalk_movies

    wait.until do
      !parse_cinematalk_movies.empty?
    end
    parse_cinematalk_movies.map { |li| li.text.strip }
  end

  def crawl_time_table(name)
    display_cinematalk_movies

    movie_xpath = XPATHS[:cinematalk_movie_list] + "/a/span[contains(text(), '"\
    "#{name}')]"
    click(parent(find(movie_xpath)))

    click(find(XPATHS[:btn_cinematalk_in_popup]))

    click(parent(find(XPATHS[:btn_seoul])))

    btn_theaters = find(XPATHS[:theater_list], multiple: true)
    btn_theaters.each do |btn_theater| # XXX: O(N^2) 😱
      click(btn_theater)
      btn_available_dates = parse_available_dates
      btn_available_dates.each do |btn_available_date|
        sleep 1 # HACK
        click(btn_available_date)
        puts parse_time_table
      end
    end
  end

  # TODO: caller of a crawler
  def call
    cinematalk_movie_list = crawl_cinematalk_movies
    cinematalk_movies = cinematalk_movie_list.map { |li| li.text.strip }

    if cinematalk_movies.empty?
      puts '시네마톡 상영 중인 영화가 없습니다.'
      return
    else
      puts '시네마톡 상영 중인 영화:'
      cinematalk_movies.each.with_index(1) do |m, i|
        puts "[#{i}] #{m}"
      end
    end

    index = user_input_to_index

    # TODO: a process that select a movie
  end

  private

  attr_reader :driver, :wait, :parser

  def display_cinematalk_movies
    driver.navigate.to(URL)
    # click the button '아트하우스'
    btn_arthouse = find(XPATHS[:btn_arthouse])
    click(btn_arthouse)

    #  and '시네마톡'
    btn_cinematalk = find(XPATHS[:btn_cinematalk])
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

  # TODO: remove when parser fully using
  def find(xpath, multiple: false)
    wait.until do
      if multiple
        driver.find_elements(:xpath, xpath)
      else
        driver.find_element(:xpath, xpath)
      end
    end
  end

  def click(element)
    wait.until { element }

    Retriable.retriable(
      tries: 5,
      on: [Selenium::WebDriver::Error::ElementClickInterceptedError]
    ) do
      element.click
    end
  end

  def parent(element)
    element.find_element(:xpath, './..')
  end

  def user_input_to_index
    # TODO: a guard for out of range
    gets.to_i - 1
  end
end
