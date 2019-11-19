require 'selenium-webdriver'
require 'retriable'

class CgvCrawler
  class NoCinematalkMovies < StandardError; end

  def initialize
    @driver = Selenium::WebDriver.for :chrome
    @wait = Selenium::WebDriver::Wait.new(timeout: 10)
  end

  URL = 'http://ticket.cgv.co.kr/Reservation/Reservation.aspx?MOVIE_CD=&MOVIE_CD_GROUP=&PLAY_YMD=&THEATER_CD=&PLAY_NUM=&PLAY_START_TM=&AREA_CD=&SCREEN_CD=&THIRD_ITEM=#'.freeze
  XPATHS = {
    btn_arthouse: "//div[@class='movie-select']/div[@class='tabmenu']/a[contains(@class, 'menu2')]",
    btn_cinematalk: "//div[@class='tabmenu-selectbox MOVIECOLLAGE']/ul/li/a[contains(text(), '시네마톡')]",
    cinematalk_movie_list: "//div[@class='movie-list nano']/ul/li",
    btn_cinematalk_in_popup: "//div[@class='selectbox-movie-type checkedBD']/ul/li/a[text()='시네마톡']",
    area_list: "//div[@class='theater-area-list']/ul/li/a"
  }.freeze

  # TODO: caller of a crawler
  def call
    cinematalk_movie_list = crawl_cinematalk_movies
    cinematalk_movies = cinematalk_movie_list.map {|li| li.text.strip}

    if cinematalk_movies.empty?
      puts '시네마톡 상영 중인 영화가 없습니다.'
      return
    else
      puts '시네마톡 상영 중인 영화:'
      cinematalk_movies.each.with_index(1) do |m, i|
        puts "[#{i}] #{m}"
      end
    end
    index = gets
    
    # TODO: a process that select a movie 
    movie_xpath = XPATHS[:cinematalk_movie_list] + "/a/span[contains(text(), '#{cinematalk_movies.first}')]"
    btn_movie = parent(find(movie_xpath))
    btn_movie.click

    btn_cinematalk_in_popup = find(XPATHS[:btn_cinematalk_in_popup])
    sleep(1) # HACK: Retriable cannot cover an unclickable situation
    btn_cinematalk_in_popup.click

    crawl_areas(btn_movie.text)
  end

  private

  attr_reader :driver, :wait

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


  def crawl_cinematalk_movies
    driver.navigate.to(URL)
    # click the button '아트하우스'
    btn_arthouse = find(XPATHS[:btn_arthouse])
    click(btn_arthouse)

    #  and '시네마톡'
    btn_cinematalk = find(XPATHS[:btn_cinematalk])
    click(btn_cinematalk)
    
    Retriable.retriable(tries: 3, on: [NoCinematalkMovies]) do
      cinematalk_movie_list = find(XPATHS[:cinematalk_movie_list], multiple: true)
      raise NoCinematalkMovies if cinematalk_movie_list.empty?

      cinematalk_movie_list
    end
  end

  def crawl_areas(movie)
    area_list = find(XPATHS[:area_list], multiple: true)
    available_area_name_list = area_list.map do |a|
      hit = a.find_element(:xpath, "./span[@class='count']").text.match(/\((?<count>\d)\)/)
      a.find_element(:xpath, "./span[@class='name']").text if hit && hit[:count] != '0'
    end.compact

    puts "#{movie} 상영관이 있는 지역:"
    available_area_name_list.each.with_index(1) do |m, i|
      puts "[#{i}] #{m}"
    end
    index = gets
  end
end