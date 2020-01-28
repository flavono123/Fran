class CgvParser
  def initialize(driver, wait)
    @driver = driver
    @wait = wait
  end

  XPATHS = {
    cinematalk_movie_list: "//div[@class='movie-list nano']/ul/li"
  }.freeze

  def parse_cinematalk_movies
    find(XPATHS[:cinematalk_movie_list], multiple: true)
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