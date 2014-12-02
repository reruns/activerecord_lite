require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map{ |key| key.to_s + '= ?'}.join(' AND ')
    vals = params.values
    q = DBConnection.execute(<<-SQL, *vals)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL
    parse_all(q)
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
