require_relative '03_associatable'

# Phase V
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    through_options = @assoc_options[through_name]
    source_options = through_options.model_class.assoc_options[source_name]
    p source_options

    define_method(name) do
      foreign_key_value = self.send(through_options.foreign_key.to_sym)
      foreign_key = source_options.foreign_key
      model_class = source_options.send(:model_class)
      through_class = through_options.send(:model_class)
      through_table = through_class.send(:table_name)
      source_class = source_options.send(:model_class)
      source_table = source_class.send(:table_name)

      result = DBConnection.execute(<<-SQL, foreign_key_value)
      SELECT
        "#{source_table}".*
      FROM
        "#{through_table}"
      JOIN
        "#{source_table}"
          ON "#{through_table}"."#{foreign_key}" = "#{source_table}".id
      WHERE
        "#{through_table}".id = ?
      SQL

      model_class.new(result.first)
    end
  end
end
