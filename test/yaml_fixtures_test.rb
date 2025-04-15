require "test_helper"
require_relative "../lib/service_factory"

class YamlFixturesTest < Minitest::Test
  FIXTURES_PATH = "test/fixtures/rbbr.io"

  def setup
    @yaml_files = Dir.glob(File.join(FIXTURES_PATH, "*.yml"))
    skip "Нет YAML-файлов для тестирования" if @yaml_files.empty?
  end

  def test_all_yaml_files_are_valid
    @yaml_files.each do |file_path|
      file_name = File.basename(file_path)
      yaml = YAML.load_file(file_path, symbolize_names: true)

      assert yaml.is_a?(Hash), "#{file_name}: файл должен содержать хеш в корне"

      yaml.each do |domain, items|
        assert items.is_a?(Hash), "#{file_name}: элементы домена #{domain} должны быть хешем"

        items.each do |service_type, data|
          service = ServiceFactory.create(data, service_type)
          refute_nil service, "#{file_name}: не удалось создать сервис для #{service_type} с данными #{data.inspect}"

          # Проверяем, что сервис имеет ожидаемую структуру
          assert_service_structure(service, file_name, service_type)
        end
      end
    end
  end

  def test_specific_yaml_file
    specific_file = File.join(FIXTURES_PATH, "complex.yml")
    skip "Файл #{specific_file} не существует" unless File.exist?(specific_file)

    yaml = YAML.load_file(specific_file, symbolize_names: true)
    assert yaml.is_a?(Hash), "complex.yml должен содержать хеш в корне"

    # Проверяем конкретные ожидаемые сервисы
    if yaml[:rbbr] && yaml[:rbbr][:integrations]
      integrations = yaml[:rbbr][:integrations]
      service = ServiceFactory.create(integrations, :integrations)

      refute_nil service, "Не удалось создать сервис для интеграций"
      assert_equal "integrations", service.service
      assert service.children.size >= 1, "Сервис интеграций должен иметь дочерние сервисы"
    end
  end

  private

  def assert_service_structure(service, file_name, service_type)
    assert service.service.is_a?(String), "#{file_name}: сервис #{service_type} должен иметь строковое имя"

    # URL может быть nil или строкой
    assert service.url.nil? || service.url.is_a?(String),
           "#{file_name}: URL для #{service_type} должен быть строкой или nil"

    # Проверяем дочерние сервисы, если они есть
    if service.children && service.children.any?
      service.children.each do |child|
        assert_service_structure(child, file_name, "#{service_type}:#{child.service}")
      end
    end
  end
end