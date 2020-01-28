# frozen_string_literal: true

class CgvParser
  def initialize(driver, wait)
    @driver = driver
    @wait = wait
  end

  XPATHS = {
    cinematalk_movie_list: "//div[@class='movie-list nano']/ul/li",
    btn_available_dates: "//div[@class='section section-date']/div[@class='col"\
    "-body']/div[@class='date-list nano']/ul/div/li[not(contains(@class, 'dimm"\
    "ed'))]/a",
    # TODO: +
    time_table: "//div[@class='section section-time']/div[@class='col-body']/d"\
    "iv[@class='time-list nano']" # TODO: + "/div/div[@class='theater']" seemed
    # it has multiple of 👆
  }.freeze

  def parse_cinematalk_movies
    find(XPATHS[:cinematalk_movie_list], multiple: true)
  end

  def parse_available_dates
    find(XPATHS[:btn_available_dates], multiple: true)
  end

  def parse_time_table
    find(XPATHS[:time_table]).text
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
end
