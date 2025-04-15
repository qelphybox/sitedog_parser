require_relative 'url_checker'
require_relative 'dictionary'
require_relative 'entities'

# Фабрика для создания объектов Service из разных форматов данных
class ServiceFactory
  # Создает объект Service из различных форматов данных
  #
  # @param data [String, Hash, Array] данные для создания сервиса
  # @param service_type [Symbol] тип сервиса (используется как запасной вариант)
  # @return [Service] созданный объект сервиса
  def self.create(data, service_type = nil)
    slug = nil
    url = nil

    case data
    in String if UrlChecker.url_like?(data) # url
      url = UrlChecker.normalize_url(data)
      slug = Dictionary.new.match(url)&.dig('name')

      slug = UrlChecker.extract_name(url) if slug.nil?

      # Используем service_type как запасной вариант, но только если не смогли
      # извлечь имя сервиса другими способами
      if slug.nil? && service_type
        slug = service_type.to_s
      end

      puts "url: #{slug} <- #{url}"
    in String if !UrlChecker.url_like?(data) # slug
      slug = data
      url = Dictionary.new.lookup(slug)&.dig('url')
      puts "slug: #{slug} -> #{url}"
    in { service: String => service_slug, url: String => service_url }
      slug = service_slug.to_s.capitalize
      url = service_url
      puts "hash: #{slug} + #{url}"
    in Hash
      puts "hash: #{data}"

      # Проверяем, содержит ли хеш только URL-подобные строки (список сервисов)
      if data.values.all? { |v| v.is_a?(String) && UrlChecker.url_like?(v) }
        puts "hash with services: #{data.keys.join(', ')}"
        # Превращаем в массив пар [service_name, url] и обрабатываем как массив
        services_array = data.map { |name, url| { service: name.to_s, url: url } }
        return create(services_array.first, service_type) if services_array.any?
      end

      # Если хеш содержит service и url (возможно с доп. полями)
      if data.key?(:service) || data.key?("service")
        key = data.key?(:service) ? :service : "service"
        slug = data[key].to_s.capitalize

        url_key = data.key?(:url) ? :url : "url"
        url = data[url_key] if data.key?(url_key)
      end
    in Array
      puts "array: #{data}"
      # Берем первый элемент массива и создаем из него сервис
      first_service = nil
      data.each do |item|
        puts "item: #{item}"
        first_service = create(item, service_type)
        break if first_service
      end
      return first_service
    end

    Service.new(service: slug, url: url)
  rescue => e
    puts "Error creating service: #{e.message}"
    puts "Data: #{data.inspect}"
    nil
  end
end