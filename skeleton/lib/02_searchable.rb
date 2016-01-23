require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)

    search_string = ""

    params.each do |key,value|
      search_string += "#{key} = '#{value}' AND "
    end

    search_string.slice!(-4..-1)
    puts "search string is #{search_string}"



  matches = DBConnection.execute(<<-SQL)
    select
      *
    from
      #{self.table_name}
    where
    #{search_string}
    SQL


    puts "matches:"
    p matches
    parse_all(matches)


  end
end

class SQLObject
  extend Searchable
end
