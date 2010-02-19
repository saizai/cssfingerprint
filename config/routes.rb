ActionController::Routing::Routes.draw do |map|
  # map.resources :sites
  # map.resources :users
  map.resources :visitations, :only => :create
  map.resources :scrapings, :only => [:new, :create], :member => {:results => :get}
  
  map.root :controller => :scrapings, :action => :new
end
