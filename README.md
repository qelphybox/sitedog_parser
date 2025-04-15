# SitedogParser

Библиотека для парсинга и классификации данных о веб-сервисах, хостинге и доменах из YAML-файлов в структурированные Ruby-объекты.

## Установка

Добавьте эту строку в Gemfile вашего приложения:

```ruby
gem 'sitedog_parser'
```

Затем выполните:

```bash
$ bundle install
```

Или установите самостоятельно:

```bash
$ gem install sitedog_parser
```

## Использование

### Базовый пример
```ruby
require 'sitedog_parser'
require 'yaml'

# Загрузка данных из YAML-файла
yaml = YAML.load_file('data.yml', symbolize_names: true)

# Создание объектов сервисов
services = {}
yaml.each do |domain, items|
  items.each do |service_type, data|
    service = ServiceFactory.create(data, service_type)
    services[service_type] ||= []
    services[service_type] << service if service
  end

  # Создание доменного объекта
  domain_obj = Domain.new(domain, services[:dns], services[:registrar])

  # Создание объекта хостинга
  hosting = Hosting.new(services[:hosting], services[:cdn], services[:ssl], services[:repo])

  # Теперь вы можете использовать domain_obj и hosting для дальнейшей обработки
end
```

### Обработка URL и имён сервисов

Библиотека автоматически нормализует URL и определяет имена сервисов:

```ruby
# Создание сервиса из URL
service = ServiceFactory.create("https://github.com/username/repo")
puts service.service  # => "Github"
puts service.url      # => "https://github.com"

# Создание сервиса из имени
service = ServiceFactory.create("GitHub")
puts service.service  # => "GitHub"
puts service.url      # => "https://github.com"
```

### Обработка сложных структур

Библиотека может обрабатывать вложенные структуры данных:

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

## Структуры данных

Библиотека предоставляет следующие основные классы:

- `Service`: Представляет веб-сервис с именем и URL
- `Domain`: Представляет информацию о домене
- `Hosting`: Представляет информацию о хостинге сайта
- `ServiceFactory`: Фабрика для создания объектов сервисов из различных форматов данных

## Развитие и вклад в проект

1. Форкните репозиторий
2. Создайте ветку для ваших изменений (`git checkout -b my-new-feature`)
3. Зафиксируйте изменения (`git commit -am 'Добавлена новая функция'`)
4. Отправьте изменения в ветку (`git push origin my-new-feature`)
5. Создайте Pull Request

## Лицензия

Этот gem доступен под лицензией MIT. Подробности см. в файле [LICENSE.txt](LICENSE.txt).