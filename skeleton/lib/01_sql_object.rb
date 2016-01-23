require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
  return @columns if @columns

  cols = DBConnection.execute2(<<-SQL).first
    select
      *
    from
      #{self.table_name}

    SQL

    @columns ||= cols.map {|col| col.to_sym}

  end

  def self.finalize!

    self.columns.each do |name|

      define_method("#{name}") do
        attributes[name]
      end

      define_method("#{name}=") do |var|
        attributes[name] = var
      end
    end

  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.new.class.to_s.tableize
  end

  def self.all

    probably_cats = self.table_name

    array = DBConnection.execute(<<-SQL)
      select
        #{probably_cats}.*
      from
        #{probably_cats}
      SQL


      self.parse_all(array)

  end

  def self.parse_all(results)
    out = results.map do |hash|
      new(hash)
    end

    out

  end

  def self.find(id)
    out = DBConnection.execute(<<-SQL)
      select
        *
      from
        #{table_name}
      where
        id = #{id}

    SQL
    return nil if out.empty?
    new(*out)
  end

  def initialize(params = {})
    params.each do |key, value|
      key = key.to_sym
      unless self.class.columns.include?(key)
        raise "unknown attribute \'#{key}\'"
      end
      self.send("#{key}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    out = []
    @attributes.each do |key, value|
      out << @attributes[key]
    end
    out
  end

  def insert
    columns = @attributes.keys.join(",")

    n = @attributes.keys.length
    values = "?"
    (n - 1).times do
      values += ", ?"
    end

    actual_values = @attributes.values

    DBConnection.execute(<<-SQL,  *actual_values)
      insert into
        #{self.class.table_name} (#{columns})
        values
        (#{values})

    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update

    big_string = ""
    actual_values = []

    @attributes.each do |key,value|
      big_string += "#{key} = ?,"
      actual_values << value
    end

    big_string.slice!(-1)
    actual_values << id

    DBConnection.execute(<<-SQL,  *actual_values)
      update
        #{self.class.table_name}
      set
        #{big_string}
      where
        #{self.class.table_name}.id = ?
    SQL

  end

  def save

    if id
      update
    else
      insert
    end

  end
end
