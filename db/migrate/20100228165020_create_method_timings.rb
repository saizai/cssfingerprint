class CreateMethodTimings < ActiveRecord::Migration
  def self.up
    create_table :method_timings do |t|
      t.string :method
      t.string :user_agent
      t.integer :timing # ms per 1kURL
      t.integer :batch_size
      t.boolean :with_variants, :default => true
      
      t.timestamps
    end
  end

  def self.down
    drop_table :method_timings
  end
end
