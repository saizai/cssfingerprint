class AddRankingIndices < ActiveRecord::Migration
  def self.up
    add_index :sites, :bloglines_rank
    add_index :sites, :google_rank
    add_index :sites, :quantcast_rank
    add_index :sites, :technorati_rank
  end

  def self.down
    remove_index :sites, :bloglines_rank
    remove_index :sites, :google_rank
    remove_index :sites, :quantcast_rank
    remove_index :sites, :technorati_rank
  end
end
