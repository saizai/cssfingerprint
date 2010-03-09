class MainController < ApplicationController
  def results
  end

  def about
    @popular_sites = Site.find(:all, :conditions => "avg_visited < 0 and visited_users_count > 5", :order => 'avg_visited')
  end

end
