class ProbabilityVector < ActiveRecord::Base
  belongs_to :user
  belongs_to :site
  # hits, tests, avg
  
  # on create:
  # 0. abort if negative and no other users have hit the site
  # 1a. if visited_users_count > 0: update aggregate a = (a * [n-1]/n) + (value/n), users_count += 1; visited_users_count += 1; add pv
  # 1b. if not: create PVs for all other users' negative tests; update aggregate a = 1/n, users_count = n; visited_users_count = 1; add pv
  
  # on update:
  # 1. increment tests; increment hits if true
  # 2. update aggregate a = a + (new avg - old avg)/n
  
  # site_results should be a hash of {siteid => visited, ...}
  def self.report user_id, site_results
    self.transaction do
      prior_pvs = self.find(:all, :lock => true, :conditions => ["site_id in (?) and user_id = ?", site_results.keys, user_id]).inject({}){|m,v| m[v.site_id] = v; m }
      new_hits = [] # site_id
      new_pvs = [] # [site_id, user_id, tests, hits, avg]
      sites = Site.find(:all, :lock => true, :conditions => ["id in (?)", site_results.keys], :select => "id, visited_users_count, users_count, avg_visited").inject([]) do |m,s|
        visited_now = site_results[s.id]
        new_avg_visited, new_users_count, new_visited_users_count = s.avg_visited, s.users_count, s.visited_users_count
        group = if prior_pvs[s.id] # already have a PV, just update it
          pv = prior_pvs[s.id]
          new_pv_hits = (visited_now ? pv.hits + 1 : pv.hits)
          new_avg = (new_pv_hits.to_f / (pv.tests + 1))
          new_avg_visited += ((new_avg - pv.avg) / new_users_count) # change the aggregate by the weighted delta of this user's PV
          new_pvs << [s.id, user_id, pv.tests + 1, new_pv_hits, new_avg]
          new_visited_users_count += 1 if visited_now and pv.hits == 0 # up the aggregated visited_users_count if this is our first *hit*
          :old
        else # new for this user
          if new_visited_users_count > 0  # other users have hit this, no need to lazy-add their stuff
            new_avg_visited = (new_avg_visited * (new_users_count - 1) / new_users_count) + ((visited_now ? 1 : 0).to_f / new_users_count)
            new_visited_users_count += 1 if visited_now
            new_users_count += 1
            new_pvs << [s.id, user_id, 1, (visited_now ? 1 : 0), 1.0]
            :new_existing
          else
            if visited_now # lazy-add the other users' PVs 
              new_hits << s.id
              new_pvs << [s.id, user_id, 1, 1, 1.0] # will also add ones for the others' down below
              :new_hit 
            else  # don't create new PVs unless it's a hit or someone else had a hit
              :noop
            end
          end
        end
        m << {:id => s.id, :group => group, :avg_visited => new_avg_visited, :users_count => new_users_count, :visited_users_count => new_visited_users_count}
        m
      end
      
      if !new_hits.empty?
        # Get all the users who "ought" to have PVs for these sites
        nohit_counts = Hash.new(0)
        Visitation.find(:all, :conditions => ['site_id IN (?)', new_hits], :joins => :scraping, :group => "site_id",
          :select => "group_concat(user_id) as user_ids, site_id").map{|v|
            users = v.user_ids.split(',').map(&:to_i).inject(Hash.new(0)){|mm,vv| mm[vv] += 1 ;mm } # hash {user_id => count, ...}
            users.each{|user, count| new_pvs << [v.site_id, user, count, 0, 0.0]
            nohit_counts[v.site_id] = users.count } }
        sites.each do |s|
          if s[:group] == :new_hit
            n = nohit_counts[s[:id]] + 1
            s[:users_count] = n
            s[:visited_users_count] = 1
            s[:avg_visited] = 1.0 / n
          end
        end
      end
      
      # Update everything, releasing their locks
      Site.import [:id, :users_count, :visited_users_count, :avg_visited], sites.map{|v| [v[:id], v[:users_count], v[:visited_users_count], v[:avg_visited]] },
        :validate => false, :on_duplicate_key_update => [:users_count, :visited_users_count, :avg_visited] 
      self.import [:site_id, :user_id, :tests, :hits, :avg], new_pvs, :validate => false, :on_duplicate_key_update => [:tests, :hits, :avg] if !new_pvs.empty?
    end
  end
  
end
