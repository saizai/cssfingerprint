class Scraping < ActiveRecord::Base
  belongs_to :user, :counter_cache => true
  has_many :visitations, :dependent => :destroy
  has_many :found_visitations, :class_name => 'Visitation', :conditions => 'visited = 1'
  has_many :found_sites, :through => :found_visitations, :class_name => 'Site', :source => :site
  
  validates_numericality_of :visitations_count
end
