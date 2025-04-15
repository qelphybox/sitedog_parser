#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require_relative '../lib/service_factory'

class YamlValidator
  def initialize(fixtures_path = 'test/fixtures/rbbr.io')
    @fixtures_path = fixtures_path
    @valid_files = []
    @invalid_files = []
    @errors = {}
  end

  def validate_all_files
    yaml_files = Dir.glob(File.join(@fixtures_path, '*.yml'))
    puts "Найдено #{yaml_files.size} YAML-файлов для проверки:"

    yaml_files.each do |file_path|
      file_name = File.basename(file_path)
      puts "\n=== Проверка файла: #{file_name} ==="

      begin
        validate_file(file_path)
        @valid_files << file_name
        puts "✅ Файл #{file_name} успешно обработан"
      rescue StandardError => e
        @invalid_files << file_name
        @errors[file_name] = e.message
        puts "❌ Ошибка при обработке файла #{file_name}: #{e.message}"
      end
    end

    print_summary
  end

  def validate_file(file_path)
    # Загружаем YAML-файл
    yaml = YAML.load_file(file_path, symbolize_names: true)

    # Проверяем, что это хеш
    raise "Файл не содержит корневой хеш" unless yaml.is_a?(Hash)

    # Обрабатываем каждый домен
    yaml.each do |domain, items|
      puts "  Обработка домена: #{domain}"

      # Проверяем, что элементы домена - это хеш
      raise "Элементы домена #{domain} не являются хешем" unless items.is_a?(Hash)

      services = {}

      # Обрабатываем каждый сервис
      items.each do |service_type, data|
        puts "    Сервис: #{service_type}"

        # Пытаемся создать сервис
        service = ServiceFactory.create(data, service_type)

        # Проверяем, что сервис создан
        if service.nil?
          raise "Не удалось создать сервис для #{service_type} с данными #{data.inspect}"
        end

        services[service_type] ||= []
        services[service_type] << service

        # Вывод информации о созданном сервисе
        print_service_info(service, 2)
      end
    end

    true
  end

  def print_service_info(service, indent = 0)
    indent_str = "  " * indent
    puts "#{indent_str}Сервис: #{service.service}"
    puts "#{indent_str}URL: #{service.url}" if service.url

    if service.children && service.children.any?
      puts "#{indent_str}Дочерние сервисы (#{service.children.size}):"
      service.children.each { |child| print_service_info(child, indent + 1) }
    end
  end

  def print_summary
    puts "\n=== Итоги проверки ==="
    puts "Всего проверено файлов: #{@valid_files.size + @invalid_files.size}"
    puts "Успешно обработано: #{@valid_files.size}"
    puts "С ошибками: #{@invalid_files.size}"

    if @invalid_files.any?
      puts "\nФайлы с ошибками:"
      @invalid_files.each do |file|
        puts "  #{file}: #{@errors[file]}"
      end
    end
  end
end

# Запускаем валидацию, если скрипт выполняется напрямую
if __FILE__ == $PROGRAM_NAME
  validator = YamlValidator.new
  validator.validate_all_files
end