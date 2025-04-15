require "test_helper"
require_relative "../lib/service_factory"

class ServiceFactoryDebugTest < Minitest::Test
  def setup
    # Хеш из примера
    @test_hash = {
      appsignal: {
        dashboard: "https://appsignal.com/rbbr/sites/67eeab66b9811010d8c90a8f/dashboard",
        errors: "https://appsignal.com/rbbr/sites/67eeab66b9811010d8c90a8f/exceptions"
      },
      managed_by: {
        service: "easypanel",
        url: "https://rbbr.space"
      }
    }
  end

  def test_infrastructure_hash
    puts "\n=== Тестирование обработки инфраструктурного хеша ==="
    # Создаем сервис и выводим его структуру
    service = ServiceFactory.create(@test_hash, :infrastructure)

    refute_nil service, "Сервис не должен быть nil"
    puts "Корневой сервис: #{service.service.inspect}"

    # Проверяем наличие дочерних сервисов
    assert_equal 2, service.children.size, "Должно быть 2 дочерних сервиса"
    service.children.each_with_index do |child, index|
      puts "Дочерний сервис #{index}: #{child.service.inspect}"
      puts "  URL: #{child.url.inspect}"
      puts "  Количество внуков: #{child.children.size}"

      child.children.each_with_index do |grandchild, gc_index|
        puts "    Внук #{gc_index}: #{grandchild.service.inspect}"
        puts "      URL: #{grandchild.url.inspect}"
      end
    end
  end

  def test_appsignal_hash
    puts "\n=== Тестирование обработки хеша appsignal ==="
    # Тестируем только хеш appsignal
    appsignal_hash = @test_hash[:appsignal]
    service = ServiceFactory.create(appsignal_hash, :appsignal)

    refute_nil service, "Сервис appsignal не должен быть nil"
    puts "Сервис: #{service.service.inspect}"
    puts "URL: #{service.url.inspect}"
    puts "Количество детей: #{service.children.size}"

    service.children.each_with_index do |child, index|
      puts "  Ребенок #{index}: #{child.service.inspect}"
      puts "    URL: #{child.url.inspect}"
    end
  end

  def test_managed_by_hash
    puts "\n=== Тестирование обработки хеша managed_by ==="
    # Тестируем только хеш managed_by
    managed_by_hash = @test_hash[:managed_by]
    service = ServiceFactory.create(managed_by_hash, :managed_by)

    refute_nil service, "Сервис managed_by не должен быть nil"
    puts "Сервис: #{service.service.inspect}"
    puts "URL: #{service.url.inspect}"
    puts "Количество детей: #{service.children.size}"
  end
end