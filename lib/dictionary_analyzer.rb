require_relative 'dictionary'

module SitedogParser
  # Class for analyzing parsing results and finding candidates for dictionary additions
  class DictionaryAnalyzer
    # Finds all services that are potentially missing from the dictionary (have a name but no URL)
    #
    # @param parsed_data [Hash] data received from Parser
    # @return [Hash] hash with candidates for dictionary addition
    def self.find_dictionary_candidates(parsed_data)
      candidates = {}
      current_dictionary = Dictionary.new

      parsed_data.each do |domain_name, services|
        services.each do |service_type, service_list|
          # Skip simple fields (non-array service lists)
          next unless service_list.is_a?(Array)

          service_list.each do |service|
            # Candidates are services that:
            # 1. Have a name
            # 2. Have no URL
            # 3. Have no children
            # 4. Are not in the current dictionary
            is_candidate = service.service &&                     # Has a name
                          !service.url &&                         # No URL
                          service.children.empty? &&              # No children
                          current_dictionary.lookup(service.service).nil?  # Not in dictionary

            if is_candidate
              # Add to candidate list with context information
              service_name = service.service.downcase
              candidates[service_name] ||= {
                name: service.service,
                service_types: [],
                domains: []
              }

              # Add service type and domain information
              candidates[service_name][:service_types] << service_type unless candidates[service_name][:service_types].include?(service_type)
              candidates[service_name][:domains] << domain_name.to_s unless candidates[service_name][:domains].include?(domain_name.to_s)
            end
          end
        end
      end

      # Sort candidates by usage frequency
      candidates.transform_values do |candidate|
        candidate[:domains_count] = candidate[:domains].size
        candidate[:types_count] = candidate[:service_types].size
        candidate
      end.sort_by { |_name, data| -data[:domains_count] }.to_h
    end

    # Analyzes data and outputs a report on dictionary candidates
    #
    # @param parsed_data [Hash] data received from Parser
    # @return [String] report on dictionary candidates
    def self.report(parsed_data)
      candidates = find_dictionary_candidates(parsed_data)

      if candidates.empty?
        return "All services have URLs or are already in the dictionary. No candidates for addition."
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

      report.join("\n")
    end
  end
end