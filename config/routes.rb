ActionController::Routing::Routes.draw do |map|
  # map.resources :sites
  # map.resources :users
  map.resources :visitations, :only => [:new, :create], :collection => [:autoscrape]
  map.resources :scrapings, :only => [:new, :create], :collection => {:results => :get}
  map.resources :browser_tests, :only => :create
  
  map.results '/results', :controller => :main, :action => :results
  map.about '/about', :controller => :main, :action => :about
  map.root :controller => :scrapings, :action => :new
end
