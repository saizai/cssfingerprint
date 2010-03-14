class AddProbabilityVectors < ActiveRecord::Migration
  def self.up
    add_column :sites, :avg_visited, :float, :default => 0
    add_column :sites, :visited_users_count, :integer, :default => 0
    create_table :probability_vectors do |t|
      t.references :user, :site, :default => nil, :null => false
      t.integer :hits, :tests, :default => 0
      t.float :avg, :default => 0
      
      t.timestamps
    end
    
    add_index :probability_vectors, [:user_id, :site_id], :unique => true
    # remove_index :sites, [:alexa_rank, :id, :url]
    add_index :sites, [:avg_visited, :alexa_rank, :id, :url], :name => :by_popularity
  end

  def self.down
    remove_column :sites, :avg_visited
    remove_column :sites, :visited_users_count
    drop_table :probability_vectors
  end
end
