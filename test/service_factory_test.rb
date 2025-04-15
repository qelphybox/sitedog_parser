require "test_helper"
require_relative "../lib/service_factory"

class ServiceFactoryTest < Minitest::Test
  FIXTURES_DICTIONARY_PATH = File.expand_path('../fixtures/dictionary.yml', __FILE__)

  def setup
    # Ничего не делаем, будем использовать реальный словарь из фикстур
  end

  def teardown
    # Ничего не делаем, так как не меняли глобальное состояние
  end

  def test_create_from_url
    # Тест с URL, который найден в словаре
    service = ServiceFactory.create("https://github.com/user/repo", nil, FIXTURES_DICTIONARY_PATH)
    assert_equal "GitHub", service.service
    assert_equal "https://github.com/user/repo", service.url

    # Тест с URL, который не найден в словаре, но имя можно извлечь
    service = ServiceFactory.create("https://example.com/path", nil, FIXTURES_DICTIONARY_PATH)
    assert_equal "example", service.service
    assert_equal "https://example.com/path", service.url

    # Тест с URL и указанным типом сервиса для запасного варианта
    service = ServiceFactory.create("https://something.weird.com", :hosting, FIXTURES_DICTIONARY_PATH)
    assert_equal "hosting", service.service
    assert_equal "https://something.weird.com", service.url
  end

  def test_create_from_slug
    # Тест с существующим slug
    service = ServiceFactory.create("github", nil, FIXTURES_DICTIONARY_PATH)
    assert_equal "GitHub", service.service
    assert_equal "https://github.com", service.url

    # Проверяем GitHub Pages с отдельным slug
    service = ServiceFactory.create("github_pages", nil, FIXTURES_DICTIONARY_PATH)
    assert_equal "GitHub Pages", service.service
    assert_equal "https://pages.github.com", service.url

    # Тест с несуществующим slug
    service = ServiceFactory.create("NonExistentService", nil, FIXTURES_DICTIONARY_PATH)
    assert_equal "NonExistentService", service.service
    assert_nil service.url
  end

  def test_create_from_hash
    # Тест с хешем
    service = ServiceFactory.create({service: "github", url: "https://github.com"}, nil, FIXTURES_DICTIONARY_PATH)
    assert_equal "Github", service.service  # Заметьте, первая буква стала заглавной
    assert_equal "https://github.com", service.url
  end

  def test_create_from_array
    # Тест с массивом строк
    service = ServiceFactory.create(["item1", "item2"], nil, FIXTURES_DICTIONARY_PATH)
    assert_nil service  # Без service_type возвращаем nil

    # Тест с массивом строк и service_type
    service = ServiceFactory.create(["item1", "item2"], :services, FIXTURES_DICTIONARY_PATH)
    refute_nil service
    assert_equal "services", service.service
    assert_equal 2, service.children.size

    # Тест с массивом хешей
    services_array = [
      { service: "github", url: "https://github.com" },
      { service: "cloudflare", url: "https://cloudflare.com" }
    ]
    service = ServiceFactory.create(services_array, :repos, FIXTURES_DICTIONARY_PATH)
    refute_nil service
    assert_equal "repos", service.service
    assert_equal 2, service.children.size
    assert_equal "Github", service.children[0].service
    assert_equal "https://github.com", service.children[0].url
    assert_equal "Cloudflare", service.children[1].service
  end

  def test_error_handling
    # Тест с невалидными данными
    service = ServiceFactory.create(nil, nil, FIXTURES_DICTIONARY_PATH)
    assert_nil service

    # Тест с данными, вызывающими исключение
    service = ServiceFactory.create({service: nil, url: "https://example.com"}, nil, FIXTURES_DICTIONARY_PATH)
    assert_nil service
  end

  def test_repository_type_detection
    # Тест для проверки, что URL репозитория определяется не как тип "repo", а как GitHub/GitLab

    # Создаем хеш с типом :repo и URL GitHub
    repo_hash = { repo: "https://github.com/inem/dopo" }
    service = ServiceFactory.create(repo_hash, :development, FIXTURES_DICTIONARY_PATH)

    refute_nil service
    assert_equal "development", service.service
    assert_equal 1, service.children.size

    # URL должен определиться как GitHub, а не просто "Repo"
    repo_service = service.children.first
    # Проверяем, что сервис определился как GitHub, а не как repo
    assert_equal "GitHub", repo_service.service
    assert_equal "https://github.com/inem/dopo", repo_service.url
    refute_nil repo_service.image_url # Должен быть URL изображения из словаря

    # Проверяем GitLab URL
    repo_hash = { repo: "https://gitlab.com/user/project" }
    service = ServiceFactory.create(repo_hash, :development, FIXTURES_DICTIONARY_PATH)

    refute_nil service
    assert_equal 1, service.children.size
    repo_service = service.children.first
    assert_equal "GitLab", repo_service.service # GitLab должен определиться из URL
    assert_equal "https://gitlab.com/user/project", repo_service.url
    refute_nil repo_service.image_url # Должен быть URL изображения из словаря
  end
end