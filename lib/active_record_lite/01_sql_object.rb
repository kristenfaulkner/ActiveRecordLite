require_relative 'db_connection'
require 'active_support/inflector'
#NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
#    of this project. It was only a warm up.

class SQLObject
  def self.columns
    @names ||= begin
      names = DBConnection.execute2("SELECT * FROM #{self.table_name}")
      names = names.first.map(&:to_sym)
    
      names.each do |name|
        define_method "#{name}=" do |value|
          attributes[name] = value
        end
        define_method "#{name}" do 
          attributes[name]
        end
      end
      names
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all
    results = DBConnection.execute("SELECT * FROM #{self.table_name}")
    p results
    self.parse_all(results)
  end
  
  def self.parse_all(results)
    results.map{ |result| self.new(result) }
  end

  def self.find(id)
    hash = DBConnection.execute(<<-SQL, id).first 
    SELECT 
      * 
    FROM 
      #{self.table_name}
    WHERE 
      id = ?
    SQL
    
    self.new(hash)
  end
  
  def attributes
    @attributes ||= Hash.new
  end

  def insert
    args = self.attribute_values
    col_names = self.class.columns.join(', ')
    question_marks = "(" + "?, " * (args.length-1) + "?)"
  
    DBConnection.execute(<<-SQL, *args)
      INSERT INTO
      #{self.class.table_name} (#{col_names})
      VALUES
      #{question_marks}
      SQL
    
    self.id = DBConnection.instance.last_insert_row_id
  end

  def initialize(params = {})
    params.each do |k,v|
      raise "unknown attribute '#{k}'" unless self.class.columns.include?(k.to_sym)
      self.send("#{k}=", v)
    end
  end

  def save
    id.nil? ? insert : update
  end
  
  def id
    attributes[:id]
  end

  def update
    args = self.attribute_values
    col_names = self.class.columns.join('=?, ') + "=?"
    DBConnection.execute(<<-SQL, *args, id)
      UPDATE
      #{self.class.table_name} 
      SET
       #{col_names}
      WHERE
        id = ?
      SQL
    
  end

  def attribute_values
    self.class.columns.map {|name| self.send("#{name}")}
  end
end
