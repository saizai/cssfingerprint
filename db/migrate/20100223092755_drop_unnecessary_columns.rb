class DropUnnecessaryColumns < ActiveRecord::Migration
  def self.up
    remove_column :visitations, :created_at
    remove_column :visitations, :updated_at
    remove_column :scrapings, :updated_at
  end

  def self.down
    raise "not worth reverting this"
  end
end
