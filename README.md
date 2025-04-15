# SitedogParser

A library for parsing and classifying web services, hosting, and domain data from YAML files into structured Ruby objects.

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

### Basic Example
```ruby
require 'sitedog_parser'
require 'yaml'

# Load data from a YAML file
yaml = YAML.load_file('data.yml', symbolize_names: true)

# Create service objects
services = {}
yaml.each do |domain, items|
  items.each do |service_type, data|
    service = ServiceFactory.create(data, service_type)
    services[service_type] ||= []
    services[service_type] << service if service
  end

  # Create domain object
  domain_obj = Domain.new(domain, services[:dns], services[:registrar])

  # Create hosting object
  hosting = Hosting.new(services[:hosting], services[:cdn], services[:ssl], services[:repo])

  # Now you can use domain_obj and hosting for further processing
end
```

### Processing URLs and Service Names

The library automatically normalizes URLs and identifies service names:

```ruby
# Create a service from a URL
service = ServiceFactory.create("https://github.com/username/repo")
puts service.service  # => "Github"
puts service.url      # => "https://github.com"

# Create a service from a name
service = ServiceFactory.create("GitHub")
puts service.service  # => "GitHub"
puts service.url      # => "https://github.com"
```

### Processing Complex Structures

The library can handle nested data structures:

```ruby
data = {
  hosting: {
    aws: "https://aws.amazon.com",
    digitalocean: "https://digitalocean.com"
  }
}

service = ServiceFactory.create(data)
puts service.service               # => "Hosting"
puts service.children.size         # => 2
puts service.children[0].service   # => "Aws"
puts service.children[0].url       # => "https://aws.amazon.com"
```

### Normalizing Different Data Formats

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

#### 6. Real-world complex example
```yaml
# Input YAML
rbbr.io:
  repo: http://github.com/rbbr-io/about
  hosting: https://console.hetzner.cloud/projects/2406094/servers/62263307/overview
  managed_by:
    service: easypanel
    url: https://rbbr.space
  ssl:
    letsencrypt # recognized as a service name
  dns:
    service: route53
    url: https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones
  registrar:
    service: namecheap
    url: https://ap.www.namecheap.com/domains/domaincontrolpanel/rbbr.io/domain
```

Processing this structure:
```ruby
yaml = YAML.load_file('example.yml', symbolize_names: true)
domain_data = yaml[:'rbbr.io']

# Services get parsed into appropriate objects
repo = ServiceFactory.create(domain_data[:repo], :repo)
hosting = ServiceFactory.create(domain_data[:hosting], :hosting)
managed_by = ServiceFactory.create(domain_data[:managed_by], :managed_by)
ssl = ServiceFactory.create(domain_data[:ssl], :ssl)
dns = ServiceFactory.create(domain_data[:dns], :dns)
registrar = ServiceFactory.create(domain_data[:registrar], :registrar)

# Creating domain object
domain = Domain.new('rbbr.io', dns, registrar)

# Domain has structured data
domain.name      # => "rbbr.io"
domain.dns.service  # => "Route53"
domain.registrar.service # => "Namecheap"
```

## Data Structures

The library provides the following main classes:

- `Service`: Represents a web service with a name and URL
- `Domain`: Represents domain information
- `Hosting`: Represents website hosting information
- `ServiceFactory`: Factory for creating service objects from various data formats

## Development and Contribution

1. Fork the repository
2. Create a branch for your changes (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a Pull Request

## License

This gem is available under the MIT license. See the [LICENSE.txt](LICENSE.txt) file for details.