class AddNullDemographics2 < ActiveRecord::Migration
  @@demos = %w(no_kids_0_17 no_kids_0_2 no_kids_3_12 no_kids_13_17).map(&:to_sym)
  
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
