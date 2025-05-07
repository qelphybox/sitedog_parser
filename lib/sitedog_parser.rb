require "sitedog_parser/version"
require 'yaml'
require 'date'
require 'json'

require_relative "service"
require_relative "dictionary"
require_relative "url_checker"
require_relative "service_factory"

module SitedogParser
  class Error < StandardError; end

  # Main parser class that provides a high-level interface to the library
  class Parser
    # By default, fields that should not be processed as services
    DEFAULT_SIMPLE_FIELDS = [:project, :role, :environment, :bought_at]

    # Parse a YAML file and convert it to structured Ruby objects
    #
    # @param file_path [String] path to the YAML file
    # @param symbolize_names [Boolean] whether to symbolize keys in the YAML file
    # @param simple_fields [Array<Symbol>] fields that should remain as simple strings without service wrapping
    # @param dictionary_path [String, nil] path to the dictionary file (optional)
    # @return [Hash] hash containing parsed services by type and domain
    def self.parse_file(file_path, symbolize_names: true, simple_fields: DEFAULT_SIMPLE_FIELDS, dictionary_path: nil)
      yaml = YAML.load_file(file_path, symbolize_names: symbolize_names)
      parse(yaml, simple_fields: simple_fields, dictionary_path: dictionary_path)
    end

    # Parse YAML data and convert it to structured Ruby objects
    #
    # @param yaml [Hash] YAML data as a hash
    # @param simple_fields [Array<Symbol>] fields that should remain as simple strings without service wrapping
    # @param dictionary_path [String, nil] path to the dictionary file (optional)
    # @return [Hash] hash containing parsed services by type and domain
    def self.parse(yaml, simple_fields: DEFAULT_SIMPLE_FIELDS, dictionary_path: nil)
      result = {}

      yaml.each do |domain_name, items|
        services = {}

        # Process each service type and its data
        items.each do |service_type, data|
          # Проверяем, является ли это поле "простым", имеет суффикс _at, или данные - экземпляр DateTime
          if simple_fields.include?(service_type) || service_type.to_s.end_with?('_at') || data.is_a?(DateTime)
            # Если данные уже DateTime, сохраняем как есть
            if data.is_a?(DateTime)
              services[service_type] = data
            # Для полей _at пробуем преобразовать строку в DateTime
            elsif service_type.to_s.end_with?('_at') && data.is_a?(String)
              begin
                services[service_type] = DateTime.parse(data)
              rescue Date::Error
                # Если не удалось преобразовать, оставляем как строку
                services[service_type] = data
              end
            else
              # Для обычных простых полей просто сохраняем значение
              services[service_type] = data
            end
          else
            # Для обычных полей создаем сервис
            service = ServiceFactory.create(data, service_type, dictionary_path)

            if service
              services[service_type] ||= []
              services[service_type] << service
            end
          end
        end

        # Create a structure with all the services
        result[domain_name] = services
      end

      result
    end

    # Преобразует YAML файл в хеш, где объекты Service преобразуются в хеши
    # @param file_path [String] путь к YAML файлу
    # @return [Hash] хеш с сервисами
    def self.to_hash(file_path)
      data = parse_file(file_path)

      # Преобразуем объекты Service в хеши
      result = {}

      data.each do |domain, services|
        domain_key = domain.to_sym  # Преобразуем ключи доменов в символы
        result[domain_key] = {}

        services.each do |service_type, service_data|
          service_type_key = service_type.to_sym  # Преобразуем ключи типов сервисов в символы

          if service_data.is_a?(Array) && service_data.first.is_a?(Service)
            # Преобразуем массив сервисов в массив хешей
            result[domain_key][service_type_key] = service_data.map do |service|
              {
                'service' => service.service,
                'url' => service.url,
                'children' => service.children.map { |child| {'service' => child.service, 'url' => child.url} }
              }
            end
          else
            # Сохраняем простые поля как есть
            result[domain_key][service_type_key] = service_data
          end
        end
      end

      result
    end

    # Преобразует данные из YAML файла в JSON формат
    #
    # @param file_path [String] путь к YAML файлу
    # @return [String] форматированная JSON строка
    def self.to_json(file_path)
      JSON.pretty_generate(to_hash(file_path))
    end
  end
end