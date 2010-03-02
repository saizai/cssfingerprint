class AddTrackingFieldsToScrapings < ActiveRecord::Migration
  def self.up
    add_column :scrapings, :finished_threads, :integer, :default => 0
    add_column :scrapings, :served_urls, :integer, :default => 0
  end

  def self.down
    remove_column :scrapings, :finished_threads
    remove_column :scrapings, :served_urls
  end
end
