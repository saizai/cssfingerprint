class AddFoundVisitationsCountToScrapings < ActiveRecord::Migration
  def self.up
    add_column :scrapings, :found_visitations_count, :integer, :default => 0, :null => false
    
    Scraping.find_each do |scraping|
      scraping.update_attribute :found_visitations_count, scraping.visitations.count(:conditions => 'visited = 1')
    end
  end

  def self.down
    remove_column :scrapings, :found_visitations_count
  end
end
