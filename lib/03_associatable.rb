require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    eval(class_name)
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    self.foreign_key = options[:foreign_key] || (name.to_s+"_id").to_sym
    self.primary_key = options[:primary_key] || :id
    self.class_name = options[:class_name] || name.to_s.singularize.camelcase
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self.foreign_key = options[:foreign_key] || (self_class_name.to_s.downcase+"_id").to_sym
    self.primary_key = options[:primary_key] || :id
    self.class_name = options[:class_name] || name.to_s.singularize.camelcase
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      options = self.class.assoc_options[name]
      fkey = options.send(:foreign_key)
      mclass = options.model_class
      q = DBConnection.execute(<<-SQL, send(fkey))
        SELECT
          *
        FROM
          #{options.table_name}
        WHERE
          id = ?
      SQL
      mclass.parse_all(q).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)

    puts "GOT THERE"
    define_method(name) do
      fkey = options.foreign_key
      pkey = options.primary_key
      mclass = options.model_class
      q = DBConnection.execute(<<-SQL, send(pkey))
       SELECT
         *
       FROM
         #{mclass.table_name}
       WHERE
         #{mclass.table_name}.#{fkey} = ?
      SQL
      mclass.parse_all(q)
    end
  end

  def assoc_options
    @assoc_options ||= {}
    @assoc_options
  end
end

class SQLObject
  extend Associatable
end
