require_relative 'db_connection'
require 'active_support/inflector'
#NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
#    of this project. It was only a warm up.

class SQLObject

  def self.columns
    column_names = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{table_name}"
    SQL

    column_names.first.map! do |name|
      name.to_sym
    end
  end

  def self.finalize!
    self.columns.each do |column_name|
      define_method(column_name) do
        @attributes[column_name]
      end

      define_method("#{column_name}=") do |argument|
        @attributes[column_name] = argument
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    if @table_name
      return @table_name
    else
      @table_name = self.to_s.tableize
    end
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
    SELECT
    *
    FROM
    '#{table_name}'
    SQL
    self.parse_all(results)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
        SELECT
          *
        FROM
          #{table_name}
        WHERE
          id = ?
        SQL
    self.parse_all(result).first
  end

  def attributes
    @attributes
  end

  def insert
    col_names = self.class.columns.join(" ,")
    question_marks = (["?"]*(self.class.columns.length)).join(", ")

    DBConnection.execute(<<-SQL,*self.attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})

    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def initialize(params = nil)
    @attributes = {}

    if !params.nil?
      params.each do |attr_name, value|
        if !self.class.columns.include?(attr_name.to_sym)
          raise "unknown attribute '#{attr_name}'"
        else
          self.send("#{attr_name}=", value)
        end
      end
    end
  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end

  def update
    update_values = self.class.columns.map do |attr_name|
      "#{attr_name} = ?"
    end
    update_values_str = update_values.join(", ")
    attribute_values_and_id = self.attribute_values
    attribute_values_and_id << self.id

    DBConnection.execute(<<-SQL,*attribute_values_and_id)
    UPDATE
      #{self.class.table_name}
    SET
      #{update_values_str}
    WHERE
      id = ?

    SQL
  end

  def attribute_values
    attribute_values = self.class.columns.map do |attr_name|
      self.send("#{attr_name}")
    end
    attribute_values
  end

end


