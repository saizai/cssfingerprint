ActionController::Routing::Routes.draw do |map|
  # map.resources :sites
  # map.resources :users
  map.resources :visitations, :only => [:new, :create], :collection => [:autoscrape]
  map.resources :scrapings, :only => [:new, :create], :collection => {:results => :get}
  
  map.root :controller => :scrapings, :action => :new
end
