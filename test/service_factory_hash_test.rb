require "test_helper"
require_relative "../lib/service_factory"

class ServiceFactoryHashTest < Minitest::Test
  def test_create_from_integrations_hash
    # Пример хеша из YAML-файла
    integrations_hash = {
      n8n: "https://n8n-n8n.7dglae.easypanel.host/workflow/hVqO0ZLaetO12ojj",
      resend: "https://resend.com/domains/e5e4ad6a-0f4e-48a8-bb3a-17465bad0b45",
      slack: "https://api.slack.com/apps/A08LS1L2QV9/oauth?",
      imgproxy: "https://rbbr.space/projects/n8n/app/imgproxy/environment",
      hubspot: "https://app-eu1.hubspot.com/contacts/145975086/objects/0-1/views/all/list"
    }

    # Проверяем, что ServiceFactory правильно обрабатывает такой хеш
    service = ServiceFactory.create(integrations_hash, :integrations)

    # Проверяем, что создан родительский сервис
    refute_nil service
    assert_equal "integrations", service.service

    # Проверяем, что все URL преобразованы в дочерние сервисы
    assert_equal 5, service.children.size

    # Проверяем, что имена и URL сервисов правильные
    n8n = service.children.find { |s| s.service == "N8n" }
    refute_nil n8n
    assert_equal "https://n8n-n8n.7dglae.easypanel.host/workflow/hVqO0ZLaetO12ojj", n8n.url

    resend = service.children.find { |s| s.service == "Resend" }
    refute_nil resend
    assert_equal "https://resend.com/domains/e5e4ad6a-0f4e-48a8-bb3a-17465bad0b45", resend.url

    slack = service.children.find { |s| s.service == "Slack" }
    refute_nil slack
    assert_equal "https://api.slack.com/apps/A08LS1L2QV9/oauth?", slack.url

    imgproxy = service.children.find { |s| s.service == "Imgproxy" }
    refute_nil imgproxy
    assert_equal "https://rbbr.space/projects/n8n/app/imgproxy/environment", imgproxy.url

    hubspot = service.children.find { |s| s.service == "Hubspot" }
    refute_nil hubspot
    assert_equal "https://app-eu1.hubspot.com/contacts/145975086/objects/0-1/views/all/list", hubspot.url
  end

  def test_create_from_hash_with_service_and_url
    # Хеш с ключами service и url
    service_hash = {
      service: "github",
      url: "https://github.com"
    }

    service = ServiceFactory.create(service_hash)

    refute_nil service
    assert_equal "Github", service.service
    assert_equal "https://github.com", service.url
  end

  def test_create_from_hash_with_extra_fields
    # Хеш с ключами service, url и дополнительными полями
    service_hash = {
      service: "github",
      url: "https://github.com",
      description: "GitHub repository",
      owner: "test-user"
    }

    service = ServiceFactory.create(service_hash)

    refute_nil service
    assert_equal "Github", service.service
    assert_equal "https://github.com", service.url
  end
end