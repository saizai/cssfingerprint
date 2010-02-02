class CreateSites < ActiveRecord::Migration
  def self.up
    # We have a unique index on url. URLs are case-sensitive.
    # Unfortunately, there is no utf8_general_cs collation in mysql, so we have to use utf8_bin if we want to respect it.
    # This will cause some weirdness if we want to sort by URL, but oh well. If that really matters, pass COLLATE=utf8_general_ci along with the ORDER BY.
    # See http://jjinux.blogspot.com/2009/03/mysql-case-sensitivity-hell.html
    
    # However, in the alexa db, there are only 34*2/1M different-case duplicates. So... fuck 'em.
    create_table :sites do |t| # , :options => 'COLLATE=utf8_bin'
      t.string :url, :null => false
      t.integer :alexa_rank
      t.integer :users_count, :default => 0
      
      t.timestamps
    end
    
    add_index :sites, :url, :unique => true
    add_index :sites, :alexa_rank
    add_index :sites, :users_count
  end

  def self.down
    drop_table :sites
  end
end
