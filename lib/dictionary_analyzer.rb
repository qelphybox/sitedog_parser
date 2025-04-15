require_relative 'dictionary'

module SitedogParser
  # Класс для анализа результатов парсинга и поиска кандидатов для добавления в словарь
  class DictionaryAnalyzer
    # Находит все сервисы, которые потенциально отсутствуют в словаре (есть имя, но нет URL)
    #
    # @param parsed_data [Hash] данные, полученные от Parser
    # @return [Hash] хеш с кандидатами для добавления в словарь
    def self.find_dictionary_candidates(parsed_data)
      candidates = {}
      current_dictionary = Dictionary.new

      parsed_data.each do |domain_name, services|
        services.each do |service_type, service_list|
          # Пропускаем простые поля (не массивы сервисов)
          next unless service_list.is_a?(Array)

          service_list.each do |service|
            # Кандидаты - это сервисы, у которых:
            # 1. Есть имя
            # 2. Нет URL
            # 3. Нет детей
            # 4. Их нет в текущем словаре
            is_candidate = service.service &&                     # Есть имя
                          !service.url &&                         # Нет URL
                          service.children.empty? &&              # Нет детей
                          current_dictionary.lookup(service.service).nil?  # Нет в словаре

            if is_candidate
              # Добавляем в список кандидатов с информацией о контексте
              service_name = service.service.downcase
              candidates[service_name] ||= {
                name: service.service,
                service_types: [],
                domains: []
              }

              # Добавляем информацию о типе сервиса и домене
              candidates[service_name][:service_types] << service_type unless candidates[service_name][:service_types].include?(service_type)
              candidates[service_name][:domains] << domain_name.to_s unless candidates[service_name][:domains].include?(domain_name.to_s)
            end
          end
        end
      end

      # Сортируем кандидатов по частоте использования
      candidates.transform_values do |candidate|
        candidate[:domains_count] = candidate[:domains].size
        candidate[:types_count] = candidate[:service_types].size
        candidate
      end.sort_by { |_name, data| -data[:domains_count] }.to_h
    end

    # Генерирует YAML для добавления кандидатов в словарь
    #
    # @param candidates [Hash] хеш кандидатов из find_dictionary_candidates
    # @return [String] YAML для добавления в словарь
    def self.generate_dictionary_yaml(candidates)
      yaml_entries = []

      candidates.each do |key, data|
        url_pattern = "(#{key}\\.|#{key}\\/)"
        service_name = data[:name]

        yaml_entries << <<~YAML
          #{key}:
            name: #{service_name}
            url: # TODO: Add URL
            url_pattern: #{url_pattern}
            aliases: # TODO: Add aliases if needed
            # Used in domains: #{data[:domains].join(', ')}
            # Used as service types: #{data[:service_types].map(&:to_s).join(', ')}
        YAML
      end

      yaml_entries.join("\n")
    end

    # Анализирует данные и выводит отчет о кандидатах в словарь
    #
    # @param parsed_data [Hash] данные, полученные от Parser
    # @return [String] отчет о кандидатах для словаря
    def self.report(parsed_data)
      candidates = find_dictionary_candidates(parsed_data)

      if candidates.empty?
        return "Все сервисы имеют URL или уже есть в словаре. Нет кандидатов для добавления."
      end

      report = [
        "DICTIONARY CANDIDATES REPORT",
        "===========================",
        "Found #{candidates.size} potential services to add to dictionary:",
        ""
      ]

      candidates.each do |name, data|
        report << "#{data[:name]}:"
        report << "  - Used in #{data[:domains_count]} domain(s): #{data[:domains].join(', ')}"
        report << "  - Used as service type(s): #{data[:service_types].map(&:to_s).join(', ')}"
        report << ""
      end

      report << "YAML Template for Dictionary:"
      report << "============================"
      report << generate_dictionary_yaml(candidates)

      report.join("\n")
    end
  end
end