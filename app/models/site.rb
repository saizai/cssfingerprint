class Site < ActiveRecord::Base
  has_many :visitations
  has_many :scrapings, :through => :visitations
  
  validates_presence_of :url, :alexa_rank, :users_count
end
