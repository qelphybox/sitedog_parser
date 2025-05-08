#!/usr/bin/env ruby
# frozen_string_literal: true

# Module for working with URL-like strings
#
# Usage:
#   require_relative 'lib/url_checker'
#
#   UrlChecker.url_like?("example.com") # => true
#   UrlChecker.url_like?("http://example.com") # => true
#   UrlChecker.url_like?("not-a-url") # => false
#
#   UrlChecker.normalize_url("example.com") # => "https://example.com"
module UrlChecker
  # Checks if a string looks like a URL
  #
  # @param string [String] string to check
  # @return [Boolean] true if the string looks like a URL, false otherwise
  def self.url_like?(string)
    return false unless string.is_a?(String)

    # Regular expression for checking URL-like strings
    # Supports various protocols and formats:
    # - standard URLs (with http, https, ftp, etc.)
    # - Git URLs (format git@hostname:user/repo.git)
    if string.match?(/^git@[a-zA-Z0-9][-a-zA-Z0-9.]+\.[a-zA-Z]{2,}:[a-zA-Z0-9\/_.-]+\.git$/)
      return true
    end

    # Check for standard URLs
    pattern = /^((?:https?|ftp|sftp|ftps|ssh|git|ws|wss):\/\/)?((?:[a-zA-Z0-9][-a-zA-Z0-9.]+\.[a-zA-Z]{2,})|(?:\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}))(:[0-9]+)?(\/[-a-zA-Z0-9%_.~#+]*)*(\?[-a-zA-Z0-9%_&=.~#+]*)?(#[-a-zA-Z0-9%_&=.~#+\/]*)?$/

    !!string.match(pattern)
  end

  # Normalizes a URL by adding a protocol if missing
  #
  # @param url [String] URL to normalize
  # @param default_protocol [String] protocol to prepend if none exists (default: "https")
  # @return [String, nil] normalized URL, or nil if input is not a valid URL
  def self.normalize_url(url, default_protocol = "https")
    return nil unless url_like?(url)

    # Git URLs remain as is
    return url if url.start_with?("git@")

    # Return as is if already has a protocol
    return url if url.match?(/^[a-zA-Z]+:\/\//)

    # Add default protocol
    "#{default_protocol}://#{url}"
  end

  # Extracts the service name from a URL
  #
  # @param url [String] URL to extract the name from
  # @return [String, nil] name of the service or nil if could not be extracted
  def self.extract_name(url)
    return nil unless url_like?(url)

    # Remove protocol and www prefix if present
    domain = url.gsub(%r{^(?:https?://)?(?:www\.)?}, "")

    # Check if it's an IP address
    if domain.match?(/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/)
      return "IP Address"
    end

    # Extract domain from URL by removing everything after first / or : or ? or #
    domain = domain.split(/[:\/?#]/).first

    # Extract the service name (usually the second-level domain)
    parts = domain.split(".")

    # If domain has enough parts (e.g., example.com, sub.example.com)
    if parts.size >= 2
      # For most domains, the second-to-last part is the name
      # e.g., example.com -> example, sub.example.com -> example
      service_name = parts[-2]

      # Special cases for country-specific TLDs with subdomains
      # e.g., example.co.uk -> example
      if parts.size >= 3 && ["co", "com", "org", "net", "ac"].include?(parts[-2])
        service_name = parts[-3]
      end

      return service_name
    end

    nil
  end
end