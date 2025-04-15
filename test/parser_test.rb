require_relative 'test_helper'

class ParserTest < Minitest::Test
  def setup
    # Create a simple YAML structure for testing
    @yaml_data = {
      'example.com' => {
        hosting: 'https://aws.amazon.com',
        dns: {
          service: 'cloudflare',
          url: 'https://cloudflare.com'
        },
        registrar: 'namecheap',
        ssl: 'letsencrypt',
        repo: 'https://github.com/example/repo'
      },
      'another-site.org' => {
        hosting: {
          service: 'digitalocean',
          url: 'https://digitalocean.com'
        },
        cdn: 'https://cloudfront.aws.amazon.com',
        dns: 'https://domains.google.com'
      }
    }
  end

  def check_domain_presence(result, domain_name)
    # Try both symbols and strings
    if result.key?(domain_name.to_sym)
      assert_includes result.keys, domain_name.to_sym
    else
      assert_includes result.keys, domain_name
    end
  end

  def get_domain_services(result, domain_name)
    # Try both symbols and strings for domain access
    if result.key?(domain_name.to_sym)
      result[domain_name.to_sym]
    else
      result[domain_name]
    end
  end

  def test_parse
    result = SitedogParser::Parser.parse(@yaml_data)

    # Check that domains are parsed correctly
    domain_keys = result.keys
    assert_equal 2, domain_keys.size
    check_domain_presence(result, 'example.com')
    check_domain_presence(result, 'another-site.org')

    # Check example.com services
    example_services = get_domain_services(result, 'example.com')
    assert_equal 5, example_services.keys.size
    assert_equal 'Amazon Web Services', example_services[:hosting].first.service
    assert_equal 'https://aws.amazon.com', example_services[:hosting].first.url
    assert_equal 'Cloudflare', example_services[:dns].first.service
    assert_equal 'https://cloudflare.com', example_services[:dns].first.url
    assert_equal 'Namecheap', example_services[:registrar].first.service
    assert_equal 'letsencrypt', example_services[:ssl].first.service
    assert_equal 'GitHub', example_services[:repo].first.service  # Должен определиться как GitHub
    assert_equal 'https://github.com/example/repo', example_services[:repo].first.url

    # Check another-site.org services
    another_services = get_domain_services(result, 'another-site.org')
    assert_equal 3, another_services.keys.size
    assert_equal 'Digitalocean', another_services[:hosting].first.service
    assert_equal 'https://digitalocean.com', another_services[:hosting].first.url
    assert_equal 'Amazon Web Services', another_services[:cdn].first.service
    assert_equal 'https://cloudfront.aws.amazon.com', another_services[:cdn].first.url
    assert_equal 'dns', another_services[:dns].first.service
    assert_equal 'https://domains.google.com', another_services[:dns].first.url
  end

  def test_get_services_by_type
    result = SitedogParser::Parser.parse(@yaml_data)

    # Get all hosting services
    hosting_services = SitedogParser::Parser.get_services_by_type(result, :hosting)
    assert_equal 2, hosting_services.size
    assert_includes hosting_services.map(&:service), 'Amazon Web Services'
    assert_includes hosting_services.map(&:service), 'Digitalocean'

    # Get all DNS services
    dns_services = SitedogParser::Parser.get_services_by_type(result, :dns)
    assert_equal 2, dns_services.size
    assert_includes dns_services.map(&:service), 'Cloudflare'
    assert_includes dns_services.map(&:service), 'dns'

    # Get service type that exists only in one domain
    cdn_services = SitedogParser::Parser.get_services_by_type(result, :cdn)
    assert_equal 1, cdn_services.size
    assert_equal 'Amazon Web Services', cdn_services.first.service

    # Try to get non-existent service type
    nonexistent_services = SitedogParser::Parser.get_services_by_type(result, :nonexistent)
    assert_empty nonexistent_services
  end

  def test_get_domain_names
    result = SitedogParser::Parser.parse(@yaml_data)
    domain_names = SitedogParser::Parser.get_domain_names(result)

    assert_equal 2, domain_names.size
    # Domain keys could be either symbols or strings, test both
    domain_names_as_strings = domain_names.map(&:to_s)
    assert_includes domain_names_as_strings, 'example.com'
    assert_includes domain_names_as_strings, 'another-site.org'
  end

  def test_parse_file
    # Create a temporary file with YAML content
    require 'tempfile'
    file = Tempfile.new(['test', '.yml'])

    begin
      file.write(@yaml_data.to_yaml)
      file.close

      # Parse the file
      result = SitedogParser::Parser.parse_file(file.path)

      # Basic check that parsing worked
      assert_equal 2, result.keys.size
      # Domain keys could be symbols
      domain_keys = result.keys.map(&:to_s)
      assert_includes domain_keys, 'example.com'
      assert_includes domain_keys, 'another-site.org'

      # Check that services were parsed using our helper method
      services = get_domain_services(result, 'example.com')
      assert services[:hosting]

      services = get_domain_services(result, 'another-site.org')
      assert services[:hosting]
    ensure
      file.unlink
    end
  end

  def test_parse_with_actual_fixture
    # Read and parse an actual fixture file
    fixture_path = File.expand_path('../fixtures/rbbr.io/simple1.yml', __FILE__)
    result = SitedogParser::Parser.parse_file(fixture_path)

    # Check that parsing was successful
    assert_instance_of Hash, result
    # Domain keys could be symbols or strings
    domain_keys = result.keys.map(&:to_s)
    assert_includes domain_keys, 'rbbr.io'
  end
end