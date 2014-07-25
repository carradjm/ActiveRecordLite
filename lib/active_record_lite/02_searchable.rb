require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.map do |key, value|
      "#{key} = ?"
    end

    where_line = where_line.join(" AND ")

    param_values = params.map do |key, value|
      value
    end

    result = DBConnection.execute(<<-SQL, param_values)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{where_line}
    SQL

    parse_all(result)
  end

end

class SQLObject
  extend Searchable
end
