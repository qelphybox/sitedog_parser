# SitedogParser

A library for parsing and classifying web services from YAML files into structured Ruby objects.

## Installation

```ruby
gem 'sitedog_parser'
```

## Usage

### Basic Usage

```ruby
require 'sitedog_parser'

# Parse from a YAML file
parsed_data = SitedogParser::Parser.parse_file('data.yml')

# Working with specific domain's services
domain_services = parsed_data['example.com']
if domain_services[:hosting]
  puts "Hosting: #{domain_services[:hosting].first.service}"
  puts "URL: #{domain_services[:hosting].first.url}"
end
```

### Simple Fields

You can specify which fields should be treated as simple values:

```ruby
# Define simple fields
simple_fields = [:project, :role, :environment, :registry]

# Parse with simple fields
parsed_data = SitedogParser::Parser.parse(yaml_data, simple_fields: simple_fields)

# Find domains with a specific field value
production_domains = SitedogParser::Parser.get_domains_by_field_value(parsed_data, :environment, 'production')
```

### Export to JSON

```ruby
# Standard output
json_data = SitedogParser::Parser.to_json('services.yml')

# Or via command line:
# $ sitedog_cli services.yml > services.json

# Compact JSON for inner objects
# $ sitedog_cli -C services.yml > services.json
```

### JSON Structure Example

```json
{
  "example.com": {
    "hosting": [{"service":"Amazon Web Services","url":"https://aws.amazon.com"}],
    "dns": [{"service":"Cloudflare","url":"https://cloudflare.com"}],
    "registrar": [{"service":"Namecheap","url":"https://namecheap.com"}]
  }
}
```

### Service Object

```ruby
service.service  # Name of the service (capitalized string)
service.url      # URL of the service (string or nil)
service.children # Child services (array of Service objects, empty if none)
```

### Supported Data Formats

The library handles various data formats:

1. **URL strings**: `"https://github.com/username/repo"` → GitHub service
2. **Service names**: `"GitHub"` → GitHub service with URL
3. **Hashes with service and URL**: `{service: "Github", url: "https://github.com/repo"}`
4. **Nested hashes** with service types
5. **Hashes with URLs** as values

### Dictionary Analysis

```ruby
# Find candidates for the dictionary (services with name but no URL)
candidates = SitedogParser::DictionaryAnalyzer.find_dictionary_candidates(parsed_data)

# Generate a report
report = SitedogParser::DictionaryAnalyzer.report(parsed_data)
```

### Command Line Options

```
$ sitedog_cli --help
Usage: sitedog_cli [options] <path_to_yaml_file> [output_file]
    -d, --debug                 Enable debug output
    -c, --compact               Compact JSON without formatting
    -C, --compact-children      Formatted JSON with compact inner objects
    -q, --quiet                 Suppress non-error messages
    -h, --help                  Show this help message
```

## License

MIT