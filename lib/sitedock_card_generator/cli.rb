require 'thor'

module SitedockCardGenerator
  class CLI < Thor
    desc "generate TYPE NAME", "Генерирует новую карточку указанного типа"
    long_desc <<-LONGDESC
      `generate TYPE NAME` создает новую карточку указанного типа с указанным именем.

      Доступные типы: article, product, service

      Пример: sitedock_card_generator generate article "Новая статья"
    LONGDESC
    def generate(type, name)
      puts "Генерация карточки типа '#{type}' с именем '#{name}'"
      # Тут будет логика генерации
    end

    desc "list", "Показывает список созданных карточек"
    def list
      puts "Список созданных карточек:"
      # Тут будет логика отображения списка
    end

    desc "version", "Показывает версию гема"
    def version
      puts "SitedockCardGenerator версия #{SitedockCardGenerator::VERSION}"
    end
  end
end