class AddJobIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :job_id, :string, :default => nil
  end

  def self.down
    remove_column :users, :job_id
  end
end
