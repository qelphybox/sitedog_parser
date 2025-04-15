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
    # Parse a YAML file and convert it to structured Ruby objects
    #
    # @param file_path [String] path to the YAML file
    # @param symbolize_names [Boolean] whether to symbolize keys in the YAML file
    # @return [Hash] hash containing parsed services by type and domain
    def self.parse_file(file_path, symbolize_names: true)
      yaml = YAML.load_file(file_path, symbolize_names: symbolize_names)
      parse(yaml)
    end

    # Parse YAML data and convert it to structured Ruby objects
    #
    # @param yaml [Hash] YAML data as a hash
    # @return [Hash] hash containing parsed services by type and domain
    def self.parse(yaml)
      result = {}

      yaml.each do |domain_name, items|
        services = {}

        # Process each service type and its data
        items.each do |service_type, data|
          service = ServiceFactory.create(data, service_type)

          if service
            services[service_type] ||= []
            services[service_type] << service
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
        if services[service_type]
          result.concat(services[service_type])
        end
      end

      result
    end

    # Get all domains from parsed data
    #
    # @param parsed_data [Hash] data returned by parse or parse_file
    # @return [Array] array of domain names
    def self.get_domain_names(parsed_data)
      parsed_data.keys
    end
  end
end