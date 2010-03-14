class MainController < ApplicationController
  def results
  end

  def about
    users_count = User.count
    @popular_sites = Site.find(:all, :conditions => "avg_visited > 0 and visited_users_count > #{round(users_count / 10)}", :order => 'avg_visited desc')
  end

end
