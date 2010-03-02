class Scraping < ActiveRecord::Base
  belongs_to :user, :counter_cache => true
  has_many :visitations, :dependent => :destroy
  has_many :found_visitations, :class_name => 'Visitation', :conditions => 'visited = 1'
  has_many :unfound_visitations, :class_name => 'Visitation', :conditions => 'visited = 0'
  has_many :found_sites, :through => :found_visitations, :class_name => 'Site', :source => :site
  has_many :unfound_sites, :through => :unfound_visitations, :class_name => 'Site', :source => :site
  
  validates_numericality_of :visitations_count
  
  def self.failed_agents
    Scraping.find(:all, :group => 'user_agent', :select => 'max(found_visitations_count) as maxfvc, user_agent', :having => 'maxfvc = 0').map(&:user_agent).sort
  end
  
  before_save :split_agent
  def split_agent
    BrowserTest.split_agent_for self
  end
end
