require "test_helper"
require_relative "../lib/url_checker"

class UrlCheckerTest < Minitest::Test
  def test_valid_urls
    valid_urls = [
      "example.com",
      "subdomain.example.com",
      "example.com/path",
      "example.com/path/to/resource",
      "example.com/path?param=value",
      "example.com:3000?a=b&c=d",
      "http://example.com",
      "http://example.com:3000",
      "http://example.com:3000?a=b&c=d",
      "https://example.com",
      "ftp://example.com",
      "git@github.com:user/repo.git",
      "https://us-east-1.console.aws.amazon.com/route53/v2/hostedzones?region=us-east-1#ListRecordSets/hf34if34iuhf3487"
    ]

    valid_urls.each do |url|
      assert UrlChecker.url_like?(url), "#{url} should be recognized as a URL"
    end
  end

  def test_invalid_urls
    invalid_urls = [
      "notaurl",
      "invalid domain.com",
      "",
      nil,
      123,
      "http:/example.com",  # invalid protocol format
      "example"             # no TLD
    ]

    invalid_urls.each do |url|
      refute UrlChecker.url_like?(url), "#{url.inspect} should not be recognized as a URL"
    end
  end

  def test_normalize_url
    # URLs without protocol should get default https://
    assert_equal "https://example.com", UrlChecker.normalize_url("example.com")
    assert_equal "https://example.com/path", UrlChecker.normalize_url("example.com/path")
    assert_equal "https://subdomain.example.com", UrlChecker.normalize_url("subdomain.example.com")
    assert_equal "https://example.com:3000", UrlChecker.normalize_url("example.com:3000")

    # URLs with protocol should remain unchanged
    assert_equal "http://example.com", UrlChecker.normalize_url("http://example.com")
    assert_equal "https://example.com", UrlChecker.normalize_url("https://example.com")
    assert_equal "ftp://example.com", UrlChecker.normalize_url("ftp://example.com")

    # Git URLs should remain unchanged
    git_url = "git@github.com:user/repo.git"
    assert_equal git_url, UrlChecker.normalize_url(git_url)

    # Custom default protocol
    assert_equal "http://example.com", UrlChecker.normalize_url("example.com", "http")

    # Invalid URLs should return nil
    assert_nil UrlChecker.normalize_url("notaurl")
    assert_nil UrlChecker.normalize_url("example")
    assert_nil UrlChecker.normalize_url(nil)
    assert_nil UrlChecker.normalize_url(123)
  end

  def test_extract_name
    # Basic domain extraction
    assert_equal "example", UrlChecker.extract_name("example.com")
    assert_equal "example", UrlChecker.extract_name("www.example.com")
    assert_equal "example", UrlChecker.extract_name("https://example.com")
    assert_equal "example", UrlChecker.extract_name("http://www.example.com")

    # With paths and query parameters
    assert_equal "example", UrlChecker.extract_name("example.com/path")
    assert_equal "example", UrlChecker.extract_name("example.com/path?query=value")
    assert_equal "example", UrlChecker.extract_name("https://example.com/path/to/resource#fragment")

    # Subdomains
    assert_equal "example", UrlChecker.extract_name("sub.example.com")
    assert_equal "example", UrlChecker.extract_name("sub.sub.example.com")

    # Country-specific TLDs
    assert_equal "example", UrlChecker.extract_name("example.co.uk")
    assert_equal "example", UrlChecker.extract_name("www.example.co.uk")
    assert_equal "example", UrlChecker.extract_name("sub.example.co.uk")

    # Popular services
    assert_equal "github", UrlChecker.extract_name("github.com")
    assert_equal "yandex", UrlChecker.extract_name("yandex.ru")
    assert_equal "google", UrlChecker.extract_name("google.com")

    # Invalid URLs
    assert_nil UrlChecker.extract_name("notaurl")
    assert_nil UrlChecker.extract_name(nil)
    assert_nil UrlChecker.extract_name(123)
  end
end