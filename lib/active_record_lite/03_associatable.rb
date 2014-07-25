require_relative '02_searchable'
require 'active_support/inflector'

# Phase IVa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    if options[:foreign_key].nil?
      @foreign_key = "#{name.capitalize}Id".underscore.to_sym
    else
      @foreign_key = options[:foreign_key]
    end

    if options[:class_name].nil?
      @class_name = "#{name.capitalize}"
    else
      @class_name = options[:class_name]
    end

    if options[:primary_key].nil?
      @primary_key = "id".to_sym
    else
      @primary_key = options[:primary_key]
    end
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    if options[:foreign_key].nil?
      @foreign_key = "#{self_class_name.capitalize}Id".underscore.to_sym
    else
      @foreign_key = options[:foreign_key]
    end

    if options[:class_name].nil?
      @class_name = "#{name.capitalize.singularize}"
    else
      @class_name = options[:class_name]
    end

    if options[:primary_key].nil?
      @primary_key = "id".to_sym
    else
      @primary_key = options[:primary_key]
    end
  end
end

module Associatable
  # Phase IVb
  def belongs_to(name, options = {})
    @assoc_options = {name => BelongsToOptions.new(name, options)}

    new_stuff = BelongsToOptions.new(name, options)

    define_method(name) do
      foreign_key_value = self.send(new_stuff.foreign_key.to_sym)
      model_class = new_stuff.send(:model_class)
      table_name = model_class.send(:table_name)

      result = DBConnection.execute(<<-SQL, foreign_key_value)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
      SQL

      model_class.new(result.first)
    end
  end

  def has_many(name, options = {})
    new_stuff = HasManyOptions.new(name.to_s, self.to_s, options)

    define_method(name) do
      foreign_key = new_stuff.send(:foreign_key)

      model_class = new_stuff.send(:model_class)

      table_name = model_class.send(:table_name)
      puts model_class.to_s + foreign_key.to_s + table_name.to_s

      results = DBConnection.execute(<<-SQL, self.id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{foreign_key} = ?
      SQL

      results.map do |result|
        model_class.new(result)
      end
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
