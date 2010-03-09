class AddMultipleRankingsToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :technorati_rank, :integer
    add_column :sites, :quantcast_rank, :integer
    add_column :sites, :bloglines_rank, :integer
    add_column :sites, :total_rank, :integer
  end
  
  def self.down
    remove_column :sites, :technorati_rank
    remove_column :sites, :quantcast_rank
    remove_column :sites, :bloglines_rank
    remove_column :sites, :total_rank
  end
end
