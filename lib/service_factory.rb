require 'pry'
require_relative 'url_checker'
require_relative 'dictionary'
require_relative 'service'
require 'logger'

# Factory for creating Service objects from different data formats
class ServiceFactory
  # Creates a Service object from various data formats
  #
  # @param data [String, Hash, Array] data for creating service
  # @param service_type [Symbol] service type (used as fallback)
  # @param dictionary_path [String, nil] path to the dictionary file (optional)
  # @param options [Hash] дополнительные опции
  # @option options [Logger] :logger логгер для вывода сообщений
  # @return [Service] created service object
  def self.create(data, service_type = nil, dictionary_path = nil, options = {})
    # Получаем логгер из опций или создаем пустой логгер, пишущий в nil
    logger = options[:logger] || Logger.new(nil)

    # Check for nil
    return nil if data.nil?

    slug = nil
    url = nil
    dictionary = Dictionary.new(dictionary_path)
    dict_entry = nil

    case data
    in String if UrlChecker.url_like?(data) # url
      url = UrlChecker.normalize_url(data)
      dict_entry = dictionary.match(url)
      slug = dict_entry&.dig('name')

      # If not found in dictionary and service_type exists, use it
      if slug.nil? && service_type
        slug = service_type.to_s
      else
        # Otherwise try to extract name from URL
        slug = UrlChecker.extract_name(url) if slug.nil?
      end

      logger.debug "url: #{slug} <- #{url}"
    in String if !UrlChecker.url_like?(data) # slug
      slug = data
      dict_entry = dictionary.lookup(slug)

      # Если нашли запись в словаре, используем её имя
      if dict_entry && dict_entry['name']
        slug = dict_entry['name']
      end

      url = dict_entry&.dig('url')
      logger.debug "slug: #{slug} -> #{url}"
    in { service: String => service_slug, url: String => service_url }
      slug = service_slug.to_s.capitalize
      url = service_url
      # Поиск в словаре после получения slug
      dict_entry = dictionary.lookup(slug)
      logger.debug "hash: #{slug} + #{url}"
    in Hash
      logger.debug "hash: #{data}"

      # Check if all values are URL-like strings
      all_url_like = data.values.all? { |v| v.is_a?(String) && UrlChecker.url_like?(v) }
      logger.debug "All values are URL-like: #{all_url_like}, values: #{data.values.map { |v| "#{v.class}: #{v}" }.join(', ')}"

      # Protection from nil values in key fields
      if (data.key?(:service) || data.key?("service")) &&
         (data[:service].nil? || data["service"].nil?)
        return nil
      end

      # 1. Check if hash contains only URL-like strings (list of services)
      if data.values.all? { |v| v.is_a?(String) && UrlChecker.url_like?(v) }
        logger.debug "hash with services: #{data.keys.join(', ')}"
        # Create array of child services
        children = []
        data.each do |key, url_value|
          service_name = key.to_s
          # Первый приоритет - поиск в словаре по URL
          child_dict_entry = dictionary.match(url_value)

          logger.debug "Child for #{key}: service_name=#{service_name}, url=#{url_value}, dict_entry=#{child_dict_entry}"

          if child_dict_entry && child_dict_entry['name']
            # Если нашли запись в словаре по URL, используем её имя вместо ключа
            service_name = child_dict_entry['name']
          else
            # Если записи в словаре нет по URL, ищем по имени
            key_dict_entry = dictionary.lookup(service_name)
            if key_dict_entry && key_dict_entry['name']
              service_name = key_dict_entry['name']
            else
              # Если не нашли в словаре ни по URL, ни по имени, капитализируем исходное имя
              service_name = service_name.capitalize
            end
          end

          child_image_url = child_dict_entry&.dig('image_url')

          child_service = Service.new(
            service: service_name,
            url: url_value,
            image_url: child_image_url
          )
          children << child_service
        end

        # Create parent service with child elements
        if service_type && children.any?
          logger.debug "Returning service for #{service_type} with #{children.size} children"
          return Service.new(service: service_type.to_s, children: children)
        elsif children.size == 1
          # If only one service and no service_type, return it
          logger.debug "Returning single child service (no service_type)"
          return children.first
        else
          logger.debug "Not returning a service for #{data.inspect}, service_type=#{service_type}, children.size=#{children.size}"
        end
      # 1.5 Check if hash contains at least some URL-like strings
      elsif data.values.any? { |v| v.is_a?(String) && UrlChecker.url_like?(v) }
        logger.debug "hash with some URL-like values: #{data.inspect}"

        # Debug: Check each value for URL-like
        data.each do |k, v|
          if v.is_a?(String)
            logger.debug "  Checking #{k}: #{v} - URL-like? #{UrlChecker.url_like?(v)}"
          else
            logger.debug "  Skipping non-string #{k}: #{v.class}"
          end
        end

        # Сохраняем все значения в properties, сохраняя порядок
        properties = {}
        data.each do |key, value|
          properties[key.to_s] = value
          logger.debug "Added property for #{key}: #{value}"
        end

        # Create service with properties only
        if !properties.empty?
          service = Service.new(
            service: service_type.to_s,
            url: nil,
            properties: properties,
            children: []  # Пустой массив children
          )
          logger.debug "Returning service with #{properties.size} properties"
          return service
        end
      end

      # 2. If hash contains service and url (possibly with additional fields)
      if (data.key?(:service) || data.key?("service")) &&
         (data.key?(:url) || data.key?("url"))
        service_key = data.key?(:service) ? :service : "service"
        service_name = data[service_key].to_s

        url_key = data.key?(:url) ? :url : "url"
        url_value = data[url_key]

        # Ищем в словаре
        service_dict_entry = dictionary.lookup(service_name) || dictionary.match(url_value)
        service_image_url = service_dict_entry&.dig('image_url')

        return Service.new(
          service: service_name.capitalize,
          url: url_value,
          image_url: service_image_url
        )
      end

      # 3. Process nested hashes
      children = []

      data.each do |key, value|
        child = nil

        if value.is_a?(Hash)
          # 3.1 If value has a hash with service and url
          if (value.key?(:service) || value.key?("service")) &&
             (value.key?(:url) || value.key?("url"))
            service_key = value.key?(:service) ? :service : "service"
            service_name = value[service_key].to_s

            url_key = value.key?(:url) ? :url : "url"
            url_value = value[url_key]

            # Ищем в словаре
            nested_dict_entry = dictionary.lookup(service_name) || dictionary.match(url_value)
            nested_image_url = nested_dict_entry&.dig('image_url')

            child = Service.new(
              service: service_name.capitalize,
              url: url_value,
              image_url: nested_image_url
            )
          # 3.2 If value has hash with only URL-like values
          elsif value.values.all? { |v| v.is_a?(String) && UrlChecker.url_like?(v) }
            child_children = []

            value.each do |sub_key, url_value|
              sub_dict_entry = dictionary.lookup(sub_key.to_s) || dictionary.match(url_value)
              sub_image_url = sub_dict_entry&.dig('image_url')

              child_children << Service.new(
                service: sub_key.to_s.capitalize,
                url: url_value,
                image_url: sub_image_url
              )
            end

            child = Service.new(service: key.to_s, children: child_children)
          # 3.3 Recursively process other cases
          else
            child = create(value, key, dictionary_path)

            # If nothing worked, create an empty service with key name
            if child.nil? && value.is_a?(Hash)
              child_children = []
              has_urls = false

              value.each do |sub_key, sub_value|
                if sub_value.is_a?(String) && UrlChecker.url_like?(sub_value)
                  has_urls = true
                  sub_dict_entry = dictionary.lookup(sub_key.to_s) || dictionary.match(sub_value)
                  sub_image_url = sub_dict_entry&.dig('image_url')

                  child_children << Service.new(
                    service: sub_key.to_s.capitalize,
                    url: sub_value,
                    image_url: sub_image_url
                  )
                end
              end

              child = Service.new(service: key.to_s, children: child_children) if has_urls
            end
          end
        # 3.4 If the value is a URL string
        elsif value.is_a?(String) && UrlChecker.url_like?(value)
          url_dict_entry = dictionary.match(value)
          url_image_url = url_dict_entry&.dig('image_url')

          child = Service.new(
            service: key.to_s.capitalize,
            url: value,
            image_url: url_image_url
          )
        end

        children << child if child
      end

      # Create parent service if there are child elements
      if children.any? && service_type
        return Service.new(service: service_type.to_s, children: children)
      elsif children.size == 1 && !service_type
        # If only one child element and no service_type, return it
        return children.first
      elsif children.any?
        # If there are child elements but no service_type, create a service with unknown name
        return Service.new(service: "Unknown", children: children)
      end
    in Array
      logger.debug "array: #{data}"

      # Create services from all array elements for children
      children = []
      data.each_with_index do |item, index|
        # Для URL-подобных строк используем стандартный механизм
        if item.is_a?(String) && UrlChecker.url_like?(item)
          child_service = create(item, service_type, dictionary_path, options)
          children << child_service if child_service
        else
          # Для простых значений создаем сервис с value
          child_service = Service.new(
            service: service_type ? service_type.to_s : "value",
            url: nil,
            properties: {},
            value: item  # Используем поле value
          )
          children << child_service
          logger.debug "Created service with value for item #{index}: #{item.inspect}"
        end
      end

      # Return service with all items as children
      if service_type
        result = Service.new(
          service: service_type.to_s,
          url: nil,
          children: children
        )
        logger.debug "Returning array service with #{children.size} children"
        return result
      end

      # Fallback to nil if no service_type
      return nil
    else
      # Handle values that don't match any pattern
      return nil
    end

    # Create service with collected data
    if slug
      # Получаем URL изображения из записи словаря, если она есть
      image_url = dict_entry&.dig('image_url')

      # Создаем сервис со всеми данными сразу
      Service.new(service: slug, url: url, image_url: image_url)
    else
      nil
    end
  rescue => e
    logger.error "Error creating service: #{e.message}"
    logger.error "Data: #{data.inspect}"
    return nil
  end
end