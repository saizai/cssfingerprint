class MainController < ApplicationController
  def results
  end
  
  def about
    users_count = User.count
    # avg_visited > 0.1 is cheaper than doing "avg_visited > 0 and visited_users_count > #{(users_count / 10).round}"
    @popular_sites = Site.find(:all, :conditions => "avg_visited > 0.1", :order => 'avg_visited desc', :select => 'avg_visited, url')
    @used_agents = BrowserTest.used_agents
    @used_methods = BrowserTest.used_methods
  end
  
end
