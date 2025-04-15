require 'yaml'

require_relative 'service'
require_relative 'dictionary'
require_relative 'url_checker'
require_relative 'service_factory'

yaml = YAML.load_file('test/fixtures/rbbr.io/full.yml', symbolize_names: true)

services = {}

yaml.each do |domain, items|
  items.each do |service_type, data|
    service = ServiceFactory.create(data, service_type)

    services[service_type] ||= []
    services[service_type] << service if service
  end

  domain = Domain.new(domain, services[:dns], services[:registrar])
  hosting = Hosting.new(services[:hosting], services[:cdn], services[:ssl], services[:repo])

  # binding.pry
end

puts
