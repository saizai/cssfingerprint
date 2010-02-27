class BrowserTestsController < ApplicationController
  def create
    results = JSON.parse(params[:results])
    results = results.inject([]){|m,i| m += i[1].map{|k,v| [i[0], k, v, request.env["HTTP_USER_AGENT"]] } ; m  }
    
    BrowserTest.import [:method, :url, :result, :user_agent], results
    
    render :inline => "Reported. Thanks!"
  end

end
