ActionController::Routing::Routes.draw do |map|
  map.resources :sites
  map.resources :users
  map.resources :visitations
  map.resources :scrapings
  
  map.root :controller => :scrapings, :action => :new
end
