class SplitUserAgent < ActiveRecord::Migration
  def self.up
    [:browser_tests, :method_timings, :scrapings].each do |t|
      [:os, :browser, :version].each do |x|
        add_column t, x, :string
      end
    end
  end

  def self.down
    [:browser_tests, :method_timings, :scrapings].each do |t|
      [:os, :browser, :version].each do |x|
        remove_column t, x
      end
    end
  end
end
