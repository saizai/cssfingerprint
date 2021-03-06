# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  filter_parameter_logging :results, :timings, :cookie, :name, :email
  
  before_filter :get_user
  
  def get_user
    @current_user = User.find(session[:user_id]) if session[:user_id] # the cookie should be signed, so this should be trustworthy
  end
  
  def effective_threads
    # be nice to the puny mobile devices
    request.user_agent.include?("Mobile") ? 1 : THREADS
  end
  helper_method :effective_threads
  
  
  def pending_jobs
    sock = TCPSocket.new('localhost', (Rails.env.production? ? 22122 : 15151))
    sock.print("stats\r\n")
    sock.flush
    jobs = nil
    until jobs 
      stats = sock.gets
      break if stats.strip == 'END'
      found = stats.scan(/STAT queue_visitation_workers__process_results_items\s(\d+)/)[0]
      jobs = found[0].to_i if found
    end
    sock.close
    jobs
  end
  helper_method :pending_jobs
end
