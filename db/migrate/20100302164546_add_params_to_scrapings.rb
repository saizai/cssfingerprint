class AddParamsToScrapings < ActiveRecord::Migration
  def self.up
    add_column :scrapings, :batch_size, :integer
    add_column :scrapings, :job_id, :string
  end
  
  def self.down
    remove_column :scrapings, :batch_size
    remove_column :scrapings, :job_id
  end
end
