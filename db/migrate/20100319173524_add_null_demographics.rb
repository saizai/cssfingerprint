class AddNullDemographics < ActiveRecord::Migration
  @@demos = %w(females eth_other college_none).map(&:to_sym)
  
  def self.up
    change_table :sites do |t|
      t.float *@@demos
    end
  end
  
  def self.down
    change_table :sites do |t|
      t.remove *@@demos
    end
  end
end
