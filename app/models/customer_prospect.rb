class CustomerProspect < ApplicationRecord
   belongs_to :customer, :class_name => 'Company'
   belongs_to :prospect, :class_name => 'Company'
end
