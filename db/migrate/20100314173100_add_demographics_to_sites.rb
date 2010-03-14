class AddDemographicsToSites < ActiveRecord::Migration
  @@demos = %w(males 
               age3_12 age13_17 age18_34 age35_49 age50plus 
               eth_caucasian eth_african eth_asian eth_hispanic 
               kids_0_17 kids_0_2 kids_3_12 kids_13_17 
               college college_grad 
               income_0_30 income_30_60 income_60_100 income_100_plus).map(&:to_sym)
  
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
