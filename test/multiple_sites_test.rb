require_relative 'test_helper'

class MultipleSitesTest < Minitest::Test
  def setup
    # Путь к тестовому файлу multiple.yaml
    @fixture_path = File.expand_path('../fixtures/multiple.yaml', __FILE__)

    # Загружаем YAML данные напрямую
    yaml_data = YAML.load_file(@fixture_path, symbolize_names: true)

    # Проверяем структуру
    assert yaml_data[:sites].is_a?(Hash), "Expected YAML with 'sites' key containing domain data"

    # Используем наш парсер для обработки данных с простыми полями
    @parsed_data = SitedogParser::Parser.parse(
      yaml_data[:sites],
      simple_fields: [:project, :role, :environment] # bought_at будет обработан автоматически
    )

    # binding.pry
  end

  def test_domains_count
    # Проверяем, что все домены были обработаны
    assert_equal 15, @parsed_data.keys.size

    # Проверяем наличие конкретных доменов
    domain_keys = @parsed_data.keys.map(&:to_s)
    assert_includes domain_keys, 'rbbr.io'
    assert_includes domain_keys, 'inem.at'
    assert_includes domain_keys, 'inem.at/jobs'
    assert_includes domain_keys, 'railshurts.com'
    assert_includes domain_keys, 'nemytchenko.ru'
    assert_includes domain_keys, 'app.setyl.com'
    assert_includes domain_keys, 'sitedock.my'
  end

  def test_service_types
    # Проверяем, что все типы сервисов были обнаружены
    all_service_types = []
    @parsed_data.each do |_domain, services|
      all_service_types.concat(services.keys)
    end
    unique_service_types = all_service_types.uniq

    expected_types = [:mail, :registrar, :dns, :hosting, :cdn, :managed_by, :repo,
                      :deploy, :monitoring, :ci, :environment, :project, :role, :bought_at]

    expected_types.each do |type|
      assert_includes unique_service_types, type, "Expected service type #{type} to be detected"
    end
  end

  def test_rbbr_io_services
    # Проверяем конкретный домен
    domain_services = get_domain_services(@parsed_data, 'rbbr.io')

    assert_equal 'G Suite', domain_services[:mail].first.service
    assert_equal 'Amazon Web Services', domain_services[:registrar].first.service
    assert_equal 'Amazon Web Services', domain_services[:dns].first.service
    assert_equal 'Amazon S3', domain_services[:hosting].first.service
  end

  def test_complex_domain
    # Проверяем домен с большим количеством сервисов
    domain_services = get_domain_services(@parsed_data, 'painlessrails.com')

    assert_equal 7, domain_services.keys.size

    assert_equal 'Amazon Web Services', domain_services[:registrar].first.service
    assert_equal 'https://gitlab.com/nemytchenko/projects/painless-rails/painless-rails-group/painless-rails-site',
                 domain_services[:repo].first.url
    assert_equal 'Ansible', domain_services[:deploy].first.service
    assert_equal 'Amazon S3', domain_services[:hosting].first.service
    assert_equal 'Cloudflare', domain_services[:cdn].first.service
    assert_equal 'Zoho Mail', domain_services[:mail].first.service
    assert_equal 'Terraform', domain_services[:managed_by].first.service
  end

  def test_simple_fields
    # Проверяем, что "простые" поля действительно остаются строками, а не превращаются в сервисы

    # Проверяем project для gitlab-ci.site
    domain_services = get_domain_services(@parsed_data, 'gitlab-ci.site')
    assert_equal 'gitlabfan', domain_services[:project]
    assert_instance_of String, domain_services[:project]

    # Проверяем role для gitlab-ci.rocks
    domain_services = get_domain_services(@parsed_data, 'gitlab-ci.rocks')
    assert_equal 'landing', domain_services[:role]
    assert_instance_of String, domain_services[:role]

    # Проверяем environment для app.setyl.com
    domain_services = get_domain_services(@parsed_data, 'app.setyl.com')
    assert_equal 'production', domain_services[:environment]
    assert_instance_of String, domain_services[:environment]
  end

  def test_bought_at_value
    # Проверяем, что registrar для sitedock.my это Namecheap
    domain_services = get_domain_services(@parsed_data, 'sitedock.my')
    assert_equal "Namecheap", domain_services[:registrar][0].service

    # Проверяем, что bought_at теперь DateTime
    assert_instance_of DateTime, domain_services[:bought_at]

    # Проверяем значения даты
    expected_date = DateTime.parse('Apr 1, 2025 01:27:35 AM')
    assert_equal expected_date.year, domain_services[:bought_at].year
    assert_equal expected_date.month, domain_services[:bought_at].month
    assert_equal expected_date.day, domain_services[:bought_at].day
    assert_equal expected_date.hour, domain_services[:bought_at].hour
    assert_equal expected_date.min, domain_services[:bought_at].min
    assert_equal expected_date.sec, domain_services[:bought_at].sec
  end

  # Вспомогательная функция для получения сервисов домена
  def get_domain_services(result, domain_name)
    # Try both symbols and strings for domain access
    if result.key?(domain_name.to_sym)
      result[domain_name.to_sym]
    else
      result[domain_name]
    end
  end
end