require "test_helper"
require_relative "../lib/service_factory"

class ServiceFactoryNestedTest < Minitest::Test
  def test_create_from_nested_hash
    # Пример вложенного хеша из YAML-файла
    infrastructure_hash = {
      appsignal: {
        dashboard: "https://appsignal.com/rbbr/sites/67eeab66b9811010d8c90a8f/dashboard",
        errors: "https://appsignal.com/rbbr/sites/67eeab66b9811010d8c90a8f/exceptions"
      },
      managed_by: {
        service: "easypanel",
        url: "https://rbbr.space"
      }
    }

    # Создаем сервис из вложенного хеша
    service = ServiceFactory.create(infrastructure_hash, :infrastructure)

    # Проверяем, что создан родительский сервис
    refute_nil service
    assert_equal "infrastructure", service.service
    assert_nil service.url

    # Проверяем дочерние сервисы
    assert_equal 2, service.children.size

    # Проверяем первый дочерний сервис (appsignal)
    appsignal = service.children.find { |s| s.service == "appsignal" }
    refute_nil appsignal
    assert_equal 2, appsignal.children.size

    # Проверяем URL-ы дочерних сервисов апсигнала
    dashboard = appsignal.children.find { |s| s.service == "Dashboard" }
    refute_nil dashboard
    assert_equal "https://appsignal.com/rbbr/sites/67eeab66b9811010d8c90a8f/dashboard", dashboard.url

    errors = appsignal.children.find { |s| s.service == "Errors" }
    refute_nil errors
    assert_equal "https://appsignal.com/rbbr/sites/67eeab66b9811010d8c90a8f/exceptions", errors.url

    # Проверяем второй дочерний сервис (Easypanel)
    easypanel = service.children.find { |s| s.service == "Easypanel" }
    refute_nil easypanel
    assert_equal "https://rbbr.space", easypanel.url
  end

  def test_create_from_nested_hash_with_mixed_types
    # Хеш с разными типами значений
    mixed_hash = {
      direct_url: "https://example.com",  # строка (URL)
      service_data: {                     # вложенный хеш
        service: "api",
        url: "https://api.example.com"
      },
      multiple_services: {                # вложенный хеш с вложенными хешами
        service1: {
          service: "service1",
          url: "https://service1.example.com"
        },
        service2: {
          service: "service2",
          url: "https://service2.example.com"
        }
      }
    }

    # Создаем сервис из смешанного хеша
    service = ServiceFactory.create(mixed_hash, :mixed)

    # Проверяем родительский сервис
    refute_nil service
    assert_equal "mixed", service.service

    # Проверяем количество дочерних сервисов
    assert_equal 3, service.children.size

    # Проверяем прямой URL-сервис
    direct_url = service.children.find { |s| s.service == "Direct_url" }
    refute_nil direct_url
    assert_equal "https://example.com", direct_url.url

    # Проверяем сервис с service и url
    api = service.children.find { |s| s.service == "Api" }
    refute_nil api
    assert_equal "https://api.example.com", api.url

    # Проверяем вложенные сервисы
    multiple_services = service.children.find { |s| s.service == "multiple_services" }
    refute_nil multiple_services
    assert_equal 2, multiple_services.children.size

    # Проверяем вложенные сервисы уровня 3
    service1 = multiple_services.children.find { |s| s.service == "Service1" }
    refute_nil service1
    assert_equal "https://service1.example.com", service1.url

    service2 = multiple_services.children.find { |s| s.service == "Service2" }
    refute_nil service2
    assert_equal "https://service2.example.com", service2.url
  end
end