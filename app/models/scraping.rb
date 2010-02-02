class Scraping < ActiveRecord::Base
  belongs_to :user, :counter_cache => true
  has_many :visitations, :dependent => :destroy
  
  validates_numericality_of :visitations_count
end
