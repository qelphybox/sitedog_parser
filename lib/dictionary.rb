#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require_relative 'url_checker'

# Class for working with the provider dictionary
class Dictionary
  # Initialize the dictionary from the YAML file
  #
  # @param dictionary_path [String] path to the dictionary YAML file
  def initialize(dictionary_path = File.expand_path('../../data/dictionary.yml', __FILE__))
    @dictionary = load_dictionary(dictionary_path)
  end

  # Look up a provider by slug or alias
  #
  # @param slug [String] provider slug or alias to look up
  # @return [Hash, nil] provider data or nil if not found
  def lookup(slug)
    return nil unless slug.is_a?(String)

    slug = slug.downcase.strip

    # Direct match by key
    return @dictionary[slug] if @dictionary.key?(slug)

    # Check aliases
    @dictionary.each do |key, provider|
      aliases = provider['aliases'].to_s.split(',').map(&:strip)
      return provider.merge('key' => key) if aliases.include?(slug)
    end

    nil
  end

  # Find a provider that matches the given URL
  #
  # @param url [String] URL to match against provider patterns
  # @return [Hash, nil] provider data or nil if no match found
  def match(url)
    return nil unless UrlChecker.url_like?(url)

    normalized_url = UrlChecker.normalize_url(url)
    return nil unless normalized_url

    @dictionary.each do |key, provider|
      pattern = provider['url_pattern']
      next unless pattern

      regexp = Regexp.new(pattern, Regexp::IGNORECASE)
      return provider.merge('key' => key) if regexp.match?(normalized_url)
    end

    nil
  end

  # Get all providers in the dictionary
  #
  # @return [Hash] the entire dictionary
  def all_providers
    @dictionary
  end

  private

  # Load the dictionary from a YAML file
  #
  # @param path [String] path to the dictionary file
  # @return [Hash] loaded dictionary
  def load_dictionary(path)
    YAML.load_file(path)
  rescue StandardError => e
    warn "Error loading dictionary: #{e.message}"
    {}
  end
end