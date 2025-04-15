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

      # Если не нашли в словаре и есть service_type, используем его
      if slug.nil? && service_type
        slug = service_type.to_s
      else
        # Иначе пытаемся извлечь имя из URL
        slug = UrlChecker.extract_name(url) if slug.nil?
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

      # 1. Проверяем, содержит ли хеш только URL-подобные строки (список сервисов)
      if data.values.all? { |v| v.is_a?(String) && UrlChecker.url_like?(v) }
        puts "hash with services: #{data.keys.join(', ')}"
        # Создаем массив дочерних сервисов
        children = []
        data.each do |key, url_value|
          service_name = key.to_s
          child_service = Service.new(service: service_name.capitalize, url: url_value)
          children << child_service
        end

        # Создаем родительский сервис с дочерними элементами
        if service_type && children.any?
          return Service.new(service: service_type.to_s, children: children)
        elsif children.size == 1
          # Если только один сервис и нет service_type, возвращаем его напрямую
          return children.first
        end
      end

      # 2. Если хеш содержит service и url (возможно с доп. полями)
      if (data.key?(:service) || data.key?("service")) &&
         (data.key?(:url) || data.key?("url"))
        service_key = data.key?(:service) ? :service : "service"
        service_name = data[service_key].to_s

        url_key = data.key?(:url) ? :url : "url"
        url_value = data[url_key]

        return Service.new(service: service_name.capitalize, url: url_value)
      end

      # 3. Обрабатываем вложенные хеши
      children = []

      data.each do |key, value|
        child = nil

        if value.is_a?(Hash)
          # 3.1 Если в значении есть хеш с service и url
          if (value.key?(:service) || value.key?("service")) &&
             (value.key?(:url) || value.key?("url"))
            service_key = value.key?(:service) ? :service : "service"
            service_name = value[service_key].to_s

            url_key = value.key?(:url) ? :url : "url"
            url_value = value[url_key]

            child = Service.new(service: service_name.capitalize, url: url_value)
          # 3.2 Если в значении есть хеш только с URL-подобными значениями
          elsif value.values.all? { |v| v.is_a?(String) && UrlChecker.url_like?(v) }
            child_children = []

            value.each do |sub_key, url_value|
              child_children << Service.new(service: sub_key.to_s.capitalize, url: url_value)
            end

            child = Service.new(service: key.to_s, children: child_children)
          # 3.3 Рекурсивно обрабатываем другие случаи
          else
            child = create(value, key)

            # Если ничего не получилось, создаем пустой сервис с именем ключа
            if child.nil? && value.is_a?(Hash)
              child_children = []
              has_urls = false

              value.each do |sub_key, sub_value|
                if sub_value.is_a?(String) && UrlChecker.url_like?(sub_value)
                  has_urls = true
                  child_children << Service.new(service: sub_key.to_s.capitalize, url: sub_value)
                end
              end

              child = Service.new(service: key.to_s, children: child_children) if has_urls
            end
          end
        # 3.4 Если значение - строка URL
        elsif value.is_a?(String) && UrlChecker.url_like?(value)
          child = Service.new(service: key.to_s.capitalize, url: value)
        end

        children << child if child
      end

      # Создаем родительский сервис, если есть дочерние элементы
      if children.any? && service_type
        return Service.new(service: service_type.to_s, children: children)
      elsif children.size == 1 && !service_type
        # Если только один дочерний элемент и нет service_type, возвращаем его
        return children.first
      elsif children.any?
        # Если есть дочерние элементы, но нет service_type, создаем сервис с неизвестным именем
        return Service.new(service: "Unknown", children: children)
      end
    in Array
      puts "array: #{data}"

      # Создаем сервисы из элементов массива
      children = data.map { |item| create(item, service_type) }.compact

      # Если есть дочерние сервисы, создаем родительский сервис с ними
      if children.any? && service_type
        return Service.new(service: service_type.to_s, children: children)
      elsif children.size == 1
        # Если только один дочерний сервис, возвращаем его
        return children.first
      end

      # Если нет дочерних сервисов или нет имени для родительского сервиса,
      # возвращаем nil
      return nil
    end

    # Создаем сервис с собранными данными
    if slug
      Service.new(service: slug, url: url)
    else
      nil
    end
  rescue => e
    puts "Error creating service: #{e.message}"
    puts "Data: #{data.inspect}"
    nil
  end
end