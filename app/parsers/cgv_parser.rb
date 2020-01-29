# frozen_string_literal: true

# TODO: rename methods; standize (e.g. remove prefixes `cinematalk_`)
class CgvParser
  def initialize(driver, wait)
    @driver = driver
    @wait = wait
  end

  XPATHS = {
    cinematalk_movies: "//div[@class='movie-list nano']/ul/li",
    available_dates: "//div[@class='section section-date']/div[@class='col-body']/div[@class='date-list nano']/ul/div/li[not(contains(@class, 'dimmed'))]/a",
    cinematalk_movie_popup: "//div[@class='selectbox-movie-type checkedBD']/ul/li/a[text()='시네마톡']",
    cinematalk_movie: proc { |name| "//div[@class='movie-list nano']/ul/li/a/span[contains(text(), '#{name}')]" },
    seoul: "//div[@class='theater-area-list']/ul/li/a/span[contains(text(), '서울')]",
    theaters: "//div[@class='theater-area-list']/ul/li[@class='selected']/div[@class='area_theater_list nano']/ul/li[not(@class='dimmed')]/a",
    time_table: "//div[@class='section section-time']/div[@class='col-body']/div[@class='time-list nano']", # TODO: + "/div/div[@class='theater']" seemed
    # it has multiple of 👆
    art_house: "//div[@class='movie-select']/div[@class='tabmenu']/a[contains(@class, 'menu2')]",
    cinematalk: "//div[@class='tabmenu-selectbox MOVIECOLLAGE']/ul/li/a[contains(text(), '시네마톡')]"
  }.freeze

  def parse(element, multiple:)
    find(XPATHS[element], multiple: multiple)
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
