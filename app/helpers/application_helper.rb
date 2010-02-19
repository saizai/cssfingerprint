# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def random_string
    3.times.map{WEBSTER.random_word}.join(' ')
  end
end
