require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    q = DBConnection.execute2(<<-SQL)
      SELECT *
      FROM #{table_name}
    SQL
    q.first.map(&:to_sym)
  end

  #be careful about using the word 'define' in directions!
  def self.finalize!
    define_method(:attributes) do
      self.instance_variable_get(:@attributes) || {}
    end

    columns.each do |col|
      define_method(col) { self.attributes[col] }
      define_method((col.to_s + '=').to_sym) do |obj|
        instance_variable_set(:@attributes, attributes.merge({col => obj}))
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name.nil? ? self.name.tableize : @table_name
  end

  def self.all
    q = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL
    parse_all(q)
  end

  def self.parse_all(results)
    out = []
    results.each do |h|
      out << self.new(h)
    end
    out
  end

  def self.find(id)
    q = DBConnection.execute(<<-SQL, id)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL
    parse_all(q).first
  end

  def initialize(params = {})
    cols = self.class.columns
    params.keys.each do |attr_name|
      att_sym = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless cols.include?(att_sym)
      self.send((attr_name.to_s+'=').to_sym, params[attr_name])
    end
  end

  def attributes
    # ...
  end

  def attribute_values
    self.class.columns.map do |col|
      send(col)
    end
  end

  def insert
    cols = self.class.columns
    col_names = cols.join(',')
    qms = ["?"] * cols.count

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{ qms.join(',') })
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    cols = self.class.columns
    setline = cols.map{ |col| col.to_s + "= ?" }.join(',')

    DBConnection.execute(<<-SQL, *attribute_values, self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{setline}
      WHERE
        id = ?
    SQL
  end

  def save
    id.nil? ? self.insert : self.update
  end
end
