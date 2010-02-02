class Visitation < ActiveRecord::Base
  belongs_to :scraping, :counter_cache => true
  belongs_to :site
  
  validates_presence_of :scraping_id, :site_id
  validates_inclusion_of :visited, :in => [true, false]
end
