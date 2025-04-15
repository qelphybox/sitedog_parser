require 'pry'
require_relative 'url_checker'
require_relative 'dictionary'
require_relative 'service'

# Factory for creating Service objects from different data formats
class ServiceFactory
  # Creates a Service object from various data formats
  #
  # @param data [String, Hash, Array] data for creating service
  # @param service_type [Symbol] service type (used as fallback)
  # @param dictionary_path [String, nil] path to the dictionary file (optional)
  # @return [Service] created service object
  def self.create(data, service_type = nil, dictionary_path = nil)
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

      puts "url: #{slug} <- #{url}"
    in String if !UrlChecker.url_like?(data) # slug
      slug = data
      dict_entry = dictionary.lookup(slug)
      url = dict_entry&.dig('url')
      puts "slug: #{slug} -> #{url}"
    in { service: String => service_slug, url: String => service_url }
      slug = service_slug.to_s.capitalize
      url = service_url
      # Поиск в словаре после получения slug
      dict_entry = dictionary.lookup(slug)
      puts "hash: #{slug} + #{url}"
    in Hash
      puts "hash: #{data}"

      # Protection from nil values in key fields
      if (data.key?(:service) || data.key?("service")) &&
         (data[:service].nil? || data["service"].nil?)
        return nil
      end

      # 1. Check if hash contains only URL-like strings (list of services)
      if data.values.all? { |v| v.is_a?(String) && UrlChecker.url_like?(v) }
        puts "hash with services: #{data.keys.join(', ')}"
        # Create array of child services
        children = []
        data.each do |key, url_value|
          service_name = key.to_s
          # Ищем в словаре по имени и URL
          child_dict_entry = dictionary.lookup(service_name) || dictionary.match(url_value)
          child_image_url = child_dict_entry&.dig('image_url')

          child_service = Service.new(
            service: service_name.capitalize,
            url: url_value,
            image_url: child_image_url
          )
          children << child_service
        end

        # Create parent service with child elements
        if service_type && children.any?
          return Service.new(service: service_type.to_s, children: children)
        elsif children.size == 1
          # If only one service and no service_type, return it directly
          return children.first
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
      puts "array: #{data}"

      # Create services from array elements
      children = data.map { |item| create(item, service_type, dictionary_path) }.compact

      # If there are child services, create a parent service with them
      if children.any? && service_type
        return Service.new(service: service_type.to_s, children: children)
      elsif children.size == 1
        # If only one child service, return it
        return children.first
      end

      # If no child services or no name for parent service,
      # return nil
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
    puts "Error creating service: #{e.message}"
    puts "Data: #{data.inspect}"
    return nil
  end
end