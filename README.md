# SitedogParser

A library for parsing and classifying web services from YAML files into structured Ruby objects.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sitedog_parser'
```

Then execute:

```bash
$ bundle install
```

Or install it yourself:

```bash
$ gem install sitedog_parser
```

## Usage

### High-Level Interface

The easiest way to use SitedogParser is through its high-level interface:

```ruby
require 'sitedog_parser'

# Parse from a YAML file
parsed_data = SitedogParser::Parser.parse_file('data.yml')

# Or parse from a hash (if you already loaded the YAML)
yaml_data = YAML.load_file('data.yml', symbolize_names: true)
parsed_data = SitedogParser::Parser.parse(yaml_data)

# Working with specific domain's services
domain_services = parsed_data['example.com']
if domain_services[:dns]
  puts "DNS service: #{domain_services[:dns].first.service}"
end
```

### Working with Simple Fields

You can specify which fields should be treated as simple string values, not as services:

```ruby
# Define which fields should remain as simple strings (not wrapped in Service objects)
simple_fields = [:project, :role, :environment, :registry]

# Parse with simple fields
parsed_data = SitedogParser::Parser.parse(yaml_data, simple_fields: simple_fields)

# Now you can access these fields directly as strings
domain_services = parsed_data['example.com']
if domain_services[:project]
  puts "Project: #{domain_services[:project]}"  # This is a string, not a Service object
end
```

### Converting to JSON

You can convert YAML data directly to JSON format:

```ruby
require 'sitedog_parser'

# Convert a YAML file to JSON
json_data = SitedogParser::Parser.to_json('services.yml')
puts json_data

# Save JSON to a file
File.write('services.json', json_data)
```

The generated JSON will have the following structure:

```json
{
  "example.com": {
    "hosting": [
      {
        "service": "Amazon Web Services",
        "url": "https://aws.amazon.com",
        "children": []
      }
    ],
    "dns": [
      {
        "service": "Cloudflare",
        "url": "https://cloudflare.com",
        "children": []
      }
    ],
    "registrar": [
      {
        "service": "Namecheap",
        "url": "https://namecheap.com",
        "children": []
      }
    ]
  }
}
```

### Finding Dictionary Candidates

You can use the DictionaryAnalyzer to find services that might be missing from your dictionary:

```ruby
require 'sitedog_parser'
require_relative 'lib/dictionary_analyzer'

# Parse your data first
parsed_data = SitedogParser::Parser.parse_file('data.yml')

# Find candidates for the dictionary (services with name but no URL)
candidates = SitedogParser::DictionaryAnalyzer.find_dictionary_candidates(parsed_data)

# Generate a report
report = SitedogParser::DictionaryAnalyzer.report(parsed_data)
puts report

# Or use the provided script
# bin/analyze_dictionary data.yml
```

The report will show:
1. A list of services that are missing from the dictionary
2. How many domains use each service
3. In which context (service type) each service is used
4. A YAML template ready to be added to your dictionary

### Example: Processing a YAML Configuration

Input YAML file (`services.yml`):

```yaml
example.com:
  hosting: https://aws.amazon.com
  dns:
    service: cloudflare
    url: https://cloudflare.com
  registrar: namecheap
  ssl: letsencrypt
  repo: https://github.com/example/repo

another-site.org:
  hosting:
    service: digitalocean
    url: https://digitalocean.com
  cdn: https://cloudfront.aws.amazon.com
  dns: https://domains.google.com
```

Processing this file:

```ruby
require 'sitedog_parser'
require 'pp'

# Parse the file
data = SitedogParser::Parser.to_json('services.yml')

# Выводим структуру данных
pp data
# Структура данных будет примерно такой:
{
  "example.com": {
    "hosting": [{"service": "Amazon Web Services", "url": "https://aws.amazon.com", "children": []}],
    "dns": [{"service": "Cloudflare", "url": "https://cloudflare.com", "children": []}],
    "registrar": [{"service": "Namecheap", "url": "https://namecheap.com", "children": []}],
    "ssl": [{"service": "Letsencrypt", "url": null, "children": []}],
    "repo": [{"service": "GitHub", "url": "https://github.com/example/repo", "children": []}]
  },
  "another-site.org": {
    "hosting": [{"service": "Digitalocean", "url": "https://digitalocean.com", "children": []}],
    "cdn": [{"service": "Amazon Web Services", "url": "https://cloudfront.aws.amazon.com", "children": []}],
    "dns": [{"service": "Google Domains", "url": "https://domains.google.com", "children": []}]
  }
}
```

### Service Object Structure

Each service object has the following structure:

```ruby
# Service fields
service.service  # Name of the service (capitalized string)
service.url      # URL of the service (string or nil)
service.children # Child services (array of Service objects, empty if none)
```

### Processing Different Data Formats

SitedogParser's strength is in normalizing different data formats into a consistent structure. Here are examples showing how various input formats are handled:

#### 1. Simple URL string
```ruby
# Input
data = "https://github.com/username/repo"

# Output
service = ServiceFactory.create(data)
service.service  # => "Github"
service.url      # => "https://github.com"
service.children # => []
```

#### 2. Service name string
```ruby
# Input
data = "GitHub"

# Output
service = ServiceFactory.create(data)
service.service  # => "GitHub"
service.url      # => "https://github.com"
service.children # => []
```

#### 3. Hash with service and URL
```ruby
# Input
data = {
  service: "Github",
  url: "https://github.com/username/repo"
}

# Output
service = ServiceFactory.create(data)
service.service  # => "Github"
service.url      # => "https://github.com/username/repo"
service.children # => []
```

#### 4. Nested hash with service types
```ruby
# Input
data = {
  dns: {
    service: "route53",
    url: "https://console.aws.amazon.com/route53"
  },
  registrar: {
    service: "namecheap",
    url: "https://namecheap.com"
  }
}

# Output
service = ServiceFactory.create(data)
service.service           # => "Unknown"
service.children.size     # => 2
service.children[0].service # => "Route53"
service.children[0].url     # => "https://console.aws.amazon.com/route53"
service.children[1].service # => "Namecheap"
service.children[1].url     # => "https://namecheap.com"
```

#### 5. Hash with URLs
```ruby
# Input
data = {
  hosting: "https://aws.amazon.com",
  cdn: "https://cloudflare.com"
}

# Output
service = ServiceFactory.create(data)
service.service           # => "Unknown"
service.children.size     # => 2
service.children[0].service # => "Hosting"
service.children[0].url     # => "https://aws.amazon.com"
service.children[1].service # => "Cdn"
service.children[1].url     # => "https://cloudflare.com"
```

## Development and Contribution

1. Fork the repository
2. Create a branch for your changes (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a Pull Request

## License

This gem is available under the MIT license. See the [LICENSE.txt](LICENSE.txt) file for details.