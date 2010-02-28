class BrowserTestsController < ApplicationController
  # To get a list of the best, non-bogus methods for each browser:
  
  # select c, avg(bogus) as bog, timing, method, user_agent from browser_tests as b inner join (
  #   select count(*) as c, avg(timing) as timing, method, user_agent 
  #   from method_timings 
  #   group by method, user_agent) as t
  # using (user_agent, method) group by method, user_agent
  # having bog < 1 order by user_agent, timing;
  
  def create
    user_agent = request.env["HTTP_USER_AGENT"]
    
    results = JSON.parse(params[:results])
    results = results.inject([]){|m,i|
      bogus = (!i[1]['cssfingerprint.com'] or i[1]['adfkljalksdflaesw.com'])
      m += i[1].map{|k,v| [i[0], k, v, bogus, user_agent] }
      m 
    }
    
    BrowserTest.import [:method, :url, :result, :bogus, :user_agent], results
    
    results = JSON.parse(params[:timings])
    results = results.inject([]){|m,i| m += i[1].map{|k,v| [i[0], k, v, user_agent] } ; m  }
    
    MethodTiming.import [:batch_size, :method, :timing, :user_agent], results
    
    render :inline => "Reported. Thanks!"
  end

end
