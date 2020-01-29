# frozen_string_literal: true

# TODO: rename methods; standize (e.g. remove prefixes `cinematalk_`)
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
    cinematalk_movie_popup: "//div[@class='selectbox-movie-type checkedBD']/u"\
    "l/li/a[text()='시네마톡']",
    cinematalk_movie: proc { |name| "//div[@class='movie-list nano']/ul/li/a/span[contains(text(), '#{name}')]" },
    seoul: "//div[@class='theater-area-list']/ul/li/a/span[contains(text(), '서울')]",
    theater_list: "//div[@class='theater-area-list']/ul/li[@class='selected']/"\
    "div[@class='area_theater_list nano']/ul/li[not(@class='dimmed')]/a",
    time_table: "//div[@class='section section-time']/div[@class='col-body']/d"\
    "iv[@class='time-list nano']", # TODO: + "/div/div[@class='theater']" seemed
    # it has multiple of 👆
    art_house: "//div[@class='movie-select']/div[@class='tabmenu']/a[contai"\
    "ns(@class, 'menu2')]",
    cinematalk: "//div[@class='tabmenu-selectbox MOVIECOLLAGE']/ul/li/a[co"\
    "ntains(text(), '시네마톡')]"
  }.freeze

  def parse_cinematalk_movies
    find(XPATHS[:cinematalk_movie_list], multiple: true)
  end

  def parse_available_dates
    find(XPATHS[:btn_available_dates], multiple: true)
  end

  def pase_theaters
    find(XPATHS[:theater_list], multiple: true)
  end

  def parse(element)
    find(XPATHS[element])
  end

  def parse_time_table
    find(XPATHS[:time_table]).text
  end

  def parse_movie(name)
    find(XPATHS[:cinematalk_movie][name])
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
