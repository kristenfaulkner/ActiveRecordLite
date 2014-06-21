require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    keys = params.keys.map {|key| "#{key} = ?"}.join(" AND ")
    values = params.values
    results = DBConnection.execute(<<-SQL, *values)
      SELECT 
        * 
      FROM 
        #{self.table_name} 
      WHERE
      #{keys}
    SQL
    results.map{ |result| self.new(result) }
  end
end

class SQLObject 
  extend Searchable
end
