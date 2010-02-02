class Scraping < ActiveRecord::Base
  belongs_to :user
  has_many :visitations, :dependent => :destroy
  
  validates_numericality_of :visitations_count
end
