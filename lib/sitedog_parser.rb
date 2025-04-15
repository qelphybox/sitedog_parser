require "sitedog_parser/version"
require 'yaml'

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
          # Проверяем, является ли это поле "простым" (не сервисом)
          if simple_fields.include?(service_type)
            # Для простых полей просто сохраняем значение без оборачивания в сервис
            services[service_type] = data
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

    # Get all services of a specific type from parsed data
    #
    # @param parsed_data [Hash] data returned by parse or parse_file
    # @param service_type [Symbol] type of service to extract
    # @return [Array] array of services of the specified type
    def self.get_services_by_type(parsed_data, service_type)
      result = []

      parsed_data.each do |_domain_name, services|
        if services[service_type] && services[service_type].is_a?(Array)
          result.concat(services[service_type])
        end
      end

      result
    end

    # Get domain names from parsed data
    #
    # @param parsed_data [Hash] data returned by parse or parse_file
    # @return [Array] array of domain names
    def self.get_domain_names(parsed_data)
      parsed_data.keys
    end

    # Get domains with a specific simple field value
    #
    # @param parsed_data [Hash] data returned by parse or parse_file
    # @param field [Symbol] simple field to filter by
    # @param value [String] value to match
    # @return [Array] array of domain names that have the specified field value
    def self.get_domains_by_field_value(parsed_data, field, value)
      result = []

      parsed_data.each do |domain_name, services|
        if services[field] == value
          result << domain_name
        end
      end

      result
    end
  end
end