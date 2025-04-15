require "test_helper"

class SitedockCardGeneratorVersionTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::SitedockCardGenerator::VERSION
  end

  def test_version_has_proper_format
    assert_match(/\d+\.\d+\.\d+/, ::SitedockCardGenerator::VERSION)
  end
end