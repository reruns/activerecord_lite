require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 03_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    through_options = self.assoc_options[through_name]

    define_method(name) do
      source_options = through_options.model_class.assoc_options[source_name]
      stable = source_options.table_name
      ttable = through_options.table_name
      sfkey = source_options.foreign_key
      spkey = source_options.primary_key
      tpkey = through_options.primary_key
      q = DBConnection.execute(<<-SQL, self.id)
        SELECT
          #{stable}.*
        FROM
          #{ttable}
        JOIN
          #{stable} ON #{ttable}.#{sfkey} = #{stable}.#{tpkey}
        WHERE
          #{stable}.#{spkey} = ?
      SQL
      source_options.model_class.parse_all(q).first
    end
  end
end
