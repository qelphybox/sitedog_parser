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

  def test_to_hash
    # Create a temporary file with YAML content
    require 'tempfile'
    file = Tempfile.new(['test', '.yml'])
    begin
      file.write(@yaml_data.to_yaml)
      file.close

      # Convert to hash
      hash_result = SitedogParser::Parser.to_hash(file.path)
      expected_hash = {
        'example.com' => {
          'hosting' => [{'service' => 'Amazon Web Services', 'url' => 'https://aws.amazon.com', 'children' => []}],
          'dns' => [{'service' => 'Cloudflare', 'url' => 'https://cloudflare.com', 'children' => []}],
          'registrar' => [{'service' => 'Namecheap', 'url' => 'https://namecheap.com', 'children' => []}],
          'ssl' => [{'service' => 'letsencrypt', 'url' => nil, 'children' => []}],
          'repo' => [{'service' => 'GitHub', 'url' => 'https://github.com/example/repo', 'children' => []}]
        },
        'another-site.org' => {
          'hosting' => [{'service' => 'Digitalocean', 'url' => 'https://digitalocean.com', 'children' => []}],
          'cdn' => [{'service' => 'Amazon Web Services', 'url' => 'https://cloudfront.aws.amazon.com', 'children' => []}],
          'dns' => [{'service' => 'dns', 'url' => 'https://domains.google.com', 'children' => []}]
        }
      }

      # Наглядная проверка структуры хешей

      # Отладочная информация - вывод всей структуры хешей
      puts "\nОжидаемый хеш:\n#{expected_hash.inspect}\n\n"
      puts "Полученный хеш:\n#{hash_result.inspect}\n\n"

      # Проверим отдельно проблемный DNS сервис в another-site.org
      another_site_dns = hash_result[:"another-site.org"][:dns].first
      puts "Проблемный DNS сервис: #{another_site_dns.inspect}"

      # 1. Проверяем домены
      assert_equal expected_hash.keys.sort, hash_result.keys.map(&:to_s).sort,
        "Несовпадение списка доменов: ожидалось #{expected_hash.keys}, получено #{hash_result.keys}"

      # 2. Для каждого домена проверяем сервисы
      expected_hash.each do |domain, exp_services|
        actual_domain_key = hash_result.keys.find { |k| k.to_s == domain }
        assert actual_domain_key, "Домен #{domain} отсутствует в результате"

        actual_services = hash_result[actual_domain_key]
        exp_service_types = exp_services.keys.sort
        actual_service_types = actual_services.keys.map(&:to_s).sort

        assert_equal exp_service_types, actual_service_types,
          "Для домена #{domain}: несовпадение типов сервисов: ожидалось #{exp_service_types}, получено #{actual_service_types}"

        # 3. Для каждого типа сервиса проверяем конкретные сервисы
        exp_services.each do |service_type, exp_service_data|
          actual_service_type = actual_services.keys.find { |k| k.to_s == service_type }
          actual_service_data = actual_services[actual_service_type]

          assert_equal exp_service_data.size, actual_service_data.size,
            "Для #{domain}/#{service_type}: разное количество сервисов: ожидалось #{exp_service_data.size}, получено #{actual_service_data.size}"

          # 4. Проверяем данные каждого сервиса
          exp_service_data.each_with_index do |exp_service, i|
            actual_service = actual_service_data[i]

            # Преобразуем ключи к строкам для единообразия сравнения
            actual_service_normalized = {}
            actual_service.each do |k, v|
              actual_service_normalized[k.to_s] = v
            end

            # Сравниваем атрибуты сервиса
            ['service', 'url'].each do |attr|
              assert_equal exp_service[attr], actual_service_normalized[attr],
                "Для #{domain}/#{service_type}[#{i}]/#{attr}: ожидалось '#{exp_service[attr]}', получено '#{actual_service_normalized[attr]}'"
            end

            # Проверяем children
            assert_equal exp_service['children'], actual_service_normalized['children'],
              "Для #{domain}/#{service_type}[#{i}]/children: ожидалось #{exp_service['children']}, получено #{actual_service_normalized['children']}"
          end
        end
      end

    ensure
      file.unlink
    end
  end
end