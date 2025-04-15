require 'yaml'
require 'pry'
require_relative 'entities'
require_relative 'dictionary'
require_relative 'url_checker'

yaml = YAML.load_file('test/fixtures/rbbr.io/complex.yml', symbolize_names: true)

services = {}

yaml.each do |domain, items|
  items.each do |service_type, data|
    slug = nil
    url = nil

    case data
    in String if UrlChecker.url_like?(data) # url
      url = UrlChecker.normalize_url(data)
      slug = Dictionary.new.match(url)&.dig('name')

      slug = UrlChecker.extract_name(url) if slug.nil?

      slug = service_type.to_s if slug.nil? # fallback to service type if no match found
      puts "url: #{slug} <- #{url}"
    in String if !UrlChecker.url_like?(data) # slug
      slug = data
      url = Dictionary.new.lookup(slug)&.dig('url')
      puts "slug: #{slug} -> #{url}"
    in { service: String => slug, url: String => url }
      slug = slug.to_s.capitalize
      puts "hash: #{slug} + #{url}"
    in Array
      puts "array: #{data}"
    end

    services[service_type] ||= []
    services[service_type] << Service.new(service: slug, url: url)
  rescue => e
    puts "Error: #{e.message}"
    puts "Data: #{data}"
    binding.pry

  end

  domain = Domain.new(domain, services[:dns], services[:registrar])
  hosting = Hosting.new(services[:hosting], services[:cdn], services[:ssl], services[:repo])

  binding.pry
end






puts
