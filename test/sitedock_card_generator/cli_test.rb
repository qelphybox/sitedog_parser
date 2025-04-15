require "test_helper"
require "stringio"

class SitedockCardGeneratorCliTest < Minitest::Test
  def setup
    @original_stdout = $stdout
    @captured_stdout = StringIO.new
    $stdout = @captured_stdout
  end

  def teardown
    $stdout = @original_stdout
  end

  def test_version_command
    SitedockCardGenerator::CLI.start(["version"])
    assert_match(/SitedockCardGenerator версия \d+\.\d+\.\d+/, @captured_stdout.string)
  end

  def test_generate_command
    type = "article"
    name = "Тестовая статья"
    SitedockCardGenerator::CLI.start(["generate", type, name])
    assert_match(/Генерация карточки типа '#{type}' с именем '#{name}'/, @captured_stdout.string)
  end

  def test_list_command
    SitedockCardGenerator::CLI.start(["list"])
    assert_match(/Список созданных карточек:/, @captured_stdout.string)
  end
end