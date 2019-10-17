require 'pry'
class Dog
    attr_reader :breed
    attr_accessor :id, :name

    def initialize(dog)
        #binding.pry
        @name = dog[:name]
        @breed = dog[:breed]
    end

    def self.create_table
        sql = <<-SQL
        CREATE TABLE IF NOT EXISTS dogs (
          id INTEGER PRIMARY KEY,
          name text,
          grade text
        )
        SQL
        DB[:conn].execute(sql)
    end

    def self.drop_table
        sql = <<-SQL
          DROP TABLE dogs
        SQL
        DB[:conn].execute(sql)
    end

    def save
        if self.id
            self.update
        else
            sql = <<-SQL
                INSERT INTO dogs (name, breed)
                VALUES (? ,?)
            SQL
            
            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
            self
        end
    end

    def self.create(dog_hash)
        dog = Dog.new(dog_hash)
        dog.save
        dog
    end

    def self.new_from_db(row)
        dog_hash = {:name=>row[1], :breed=>row[2]}
        dog = self.new(dog_hash)
        dog.id = row[0]
        dog
    end

    def self.find_by_id(id)
        sql = <<-SQL
            SELECT * FROM dogs 
            where id = ?
        SQL

        DB[:conn].execute(sql, id).map do |row|
            self.new_from_db(row)
        end.first
    end

    def self.find_or_create_by(name:, breed:)
        dog = DB[:conn].execute("SELECT * FROM dogs WHERE name = ? AND breed = ?", name, breed)
        dog_hash = {:name=>name, :breed=>breed}
        #binding.pry
        if !dog.empty?
            #binding.pry
            #returns dog if the dog exists
            id = dog[0][0]
            dog = Dog.new(dog_hash)
            dog.id = id
        else
            #creates a dog row 
            dog = self.create(dog_hash)
        end
        dog
    end

    def self.find_by_name(name)
        sql = <<-SQL
            SELECT * 
            FROM dogs
            WHERE name = ?
        SQL

        DB[:conn].execute(sql, name).map do |row|
            self.new_from_db(row)
        end.first
    end

    def update
        sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?"
        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end
end