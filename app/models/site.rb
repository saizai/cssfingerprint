class Site < ActiveRecord::Base
  has_many :visitations
  has_many :scrapings, :through => :visitations
  has_many :found_visitations, :class_name => 'Visitation', :conditions => 'visited = 1'
  has_many :found_scrapings, :class_name => 'Scraping', :through => :found_visitations, :source => :scraping
  
  validates_presence_of :url, :alexa_rank, :users_count
end
