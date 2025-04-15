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
    appsignal = service.children.find { |s| s.service == "Appsignal" }
    refute_nil appsignal
    assert_equal 2, appsignal.children.size

    # Проверяем второй дочерний сервис (managed_by)
    managed_by = service.children.find { |s| s.service == "Easypanel" }
    refute_nil managed_by
    assert_equal "https://rbbr.space", managed_by.url
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
    assert service.children.size >= 2, "Должно быть как минимум 2 дочерних сервиса"

    # Проверяем наличие дочерних сервисов по имени
    service_data = service.children.find { |s| s.service == "Api" }
    refute_nil service_data
    assert_equal "https://api.example.com", service_data.url

    # Проверяем вложенные сервисы второго уровня
    multiple_services = service.children.find { |s| s.service == "multiple_services" }
    refute_nil multiple_services
    assert_equal 2, multiple_services.children.size
  end
end