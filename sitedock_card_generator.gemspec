require_relative 'lib/sitedock_card_generator/version'

Gem::Specification.new do |spec|
  spec.name          = "sitedock_card_generator"
  spec.version       = SitedockCardGenerator::VERSION
  spec.authors       = ["Your Name"]
  spec.email         = ["your.email@example.com"]

  spec.summary       = "Генератор карточек для сайта"
  spec.description   = "Инструмент для автоматического создания и управления карточками контента для сайтов"
  spec.homepage      = "https://github.com/yourusername/sitedock-card-generator"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  # Укажите, какие файлы будут включены в гем
  spec.files = Dir[
    "lib/**/*",
    "bin/*",
    "LICENSE.txt",
    "README.md",
    "CHANGELOG.md"
  ]

  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Зависимости для разработки
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"

  # Рабочие зависимости
  spec.add_dependency "thor", "~> 1.2"  # Для CLI
end