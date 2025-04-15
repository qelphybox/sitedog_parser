require "test_helper"
require_relative "../lib/dictionary"

class DictionaryTest < Minitest::Test
  def setup
    @dictionary = Dictionary.new
  end

  def test_lookup_by_key
    # Test lookup by key
    provider = @dictionary.lookup('namecheap')
    refute_nil provider
    assert_equal 'Namecheap', provider['name']
  end

  def test_lookup_by_alias
    # Test lookup by alias
    provider = @dictionary.lookup('name-cheap')
    refute_nil provider
    assert_equal 'Namecheap', provider['name']
    assert_equal 'namecheap', provider['key']
  end

  def test_lookup_case_insensitive
    # Test case insensitivity
    provider = @dictionary.lookup('GODADDY')
    refute_nil provider
    assert_equal 'GoDaddy', provider['name']
  end

  def test_lookup_nonexistent
    # Test looking up a nonexistent provider
    provider = @dictionary.lookup('nonexistent-provider')
    assert_nil provider
  end

  def test_match_url
    # Test URL matching
    urls = {
      'https://namecheap.com/domain-name-search' => 'Namecheap',
      'https://www.godaddy.com' => 'GoDaddy',
      'namecheap.com' => 'Namecheap',
      'app.netlify.com/sites' => 'Netlify',
      'mysite.netlify.app' => 'Netlify',
      'user-project.github.io' => 'GitHub Pages',
      'https://myapp.herokuapp.com' => 'Heroku',
      'example.firebaseapp.com' => 'Firebase Hosting'
    }

    urls.each do |url, expected_name|
      provider = @dictionary.match(url)
      refute_nil provider, "Should match URL: #{url}"
      assert_equal expected_name, provider['name'], "URL #{url} should match provider #{expected_name}"
    end
  end

  def test_match_invalid_url
    # Test matching an invalid URL
    provider = @dictionary.match('not-a-url')
    assert_nil provider
  end

  def test_match_unmatched_url
    # Test matching a valid URL that doesn't match any provider
    provider = @dictionary.match('https://example.com')
    assert_nil provider
  end

  def test_all_providers
    # Test retrieving all providers
    providers = @dictionary.all_providers
    refute_empty providers
    assert_includes providers.keys, 'namecheap'
    assert_includes providers.keys, 'github'
  end
end