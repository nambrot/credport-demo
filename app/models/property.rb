class Property < ActiveRecord::Base
  attr_accessible :desc, :title
  belongs_to :user
end
