class AddGoogleRankToSites < ActiveRecord::Migration
  def self.up
    change_column :sites, :total_rank, :float
    add_column :sites, :google_rank, :integer
    
    remove_index :sites, :name => :by_popularity
    add_index :sites, [:avg_visited, :total_rank, :id, :url], :name => :by_popularity 
    Site.update "avg_visited = -avg_visited", "avg_visited < 0"
    Site.update "alexa_rank = null", "alexa_rank = 0"
    Site.update_all "total_rank = if(alexa_rank IS NULL or alexa_rank == 0,((1000000 - alexa_rank) / 1000000.0)), null)"
  end

  def self.down
    remove_column :sites, :google_rank
  end
end
