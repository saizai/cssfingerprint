class MethodTiming < ActiveRecord::Base
  
  before_save :split_agent
  def split_agent
    BrowserTest.split_agent_for self
  end
end
