require "test_helper"
require_relative "../lib/service_factory"

class ServiceFactoryTest < Minitest::Test
  def setup
    # Мокаем Dictionary для тестов
    @dictionary_mock = Minitest::Mock.new
    @original_dictionary = Dictionary
    Object.send(:remove_const, :Dictionary)

    dictionary_class = Class.new do
      def match(url)
        if url.include?("github")
          {"name" => "GitHub"}
        else
          nil
        end
      end

      def lookup(slug)
        if slug == "GitHub"
          {"url" => "https://github.com"}
        else
          nil
        end
      end
    end

    Object.const_set(:Dictionary, dictionary_class)
  end

  def teardown
    # Восстанавливаем оригинальный Dictionary
    Object.send(:remove_const, :Dictionary)
    Object.const_set(:Dictionary, @original_dictionary)
  end

  def test_create_from_url
    # Тест с URL, который найден в словаре
    service = ServiceFactory.create("https://github.com/user/repo")
    assert_equal "GitHub", service.service
    assert_equal "https://github.com/user/repo", service.url

    # Тест с URL, который не найден в словаре, но имя можно извлечь
    service = ServiceFactory.create("https://example.com/path")
    assert_equal "example", service.service
    assert_equal "https://example.com/path", service.url

    # Тест с URL и указанным типом сервиса для запасного варианта
    service = ServiceFactory.create("https://something.weird.com", :hosting)
    assert_equal "hosting", service.service
    assert_equal "https://something.weird.com", service.url
  end

  def test_create_from_slug
    # Тест с существующим slug
    service = ServiceFactory.create("GitHub")
    assert_equal "GitHub", service.service
    assert_equal "https://github.com", service.url

    # Тест с несуществующим slug
    service = ServiceFactory.create("NonExistentService")
    assert_equal "NonExistentService", service.service
    assert_nil service.url
  end

  def test_create_from_hash
    # Тест с хешем
    service = ServiceFactory.create({service: "github", url: "https://github.com"})
    assert_equal "Github", service.service  # Заметьте, первая буква стала заглавной
    assert_equal "https://github.com", service.url
  end

  def test_create_from_array
    # Тест с массивом (пока возвращает nil)
    service = ServiceFactory.create(["item1", "item2"])
    assert_nil service
  end

  def test_error_handling
    # Тест с невалидными данными
    service = ServiceFactory.create(nil)
    assert_nil service

    # Тест с данными, вызывающими исключение
    service = ServiceFactory.create({service: nil, url: "https://example.com"})
    assert_nil service
  end
end