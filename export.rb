require 'rubygems'
require 'bundler/setup'

require 'sqlite3'
require 'uri'

class Export

  def initialize(exaile_db_path, clementine_db_path)
    @exaile_db = SQLite3::Database.open exaile_db_path
    @exaile_db.results_as_hash = true
    
    @clementine_db = SQLite3::Database.open clementine_db_path
    @clementine_db.results_as_hash = true
  end
  
  def process
    stm = @exaile_db.prepare "select tracks.title, tracks.user_rating, paths.name from tracks inner join paths on (tracks.path=paths.id) where tracks.user_rating>'0'"
    rows = stm.execute
    
    i = 0    
    rows.each do |row|
      i += 1
      puts i
      set_clementine_rating row['name'], row['user_rating']
    end

    puts 'Done'
  end
  
  def set_clementine_rating(path, rating)
    #begin
      stm = @clementine_db.prepare "update songs set rating=? where filename=? and rating<=?"
      stm.bind_params rating_convert(rating), SQLite3::Blob.new(to_clementine_path(path)), 0
      stm.execute
    #rescue SQLite3::Exception => e
    #  puts 'SQLite exception'
    #  puts e
    #end
  end
  
  def to_clementine_path(path)
    "file://#{URI.escape(path)}"
  end
  
  def rating_convert(rating)
    (rating.to_f*2)/10
  end
  
end

if ARGV[0] == '--help'
  puts 'Usage: $ ruby export.rb <exaile_db_path> <clementine_db_path>'
else
  exaile_db_path = ARGV[0]
  clementine_db_path = ARGV[1]

  export = Export.new(exaile_db_path, clementine_db_path)
  export.process
end
