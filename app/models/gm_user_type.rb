class GmUserType < ActiveRecord::Base
  unloadable
  belongs_to :user
end
