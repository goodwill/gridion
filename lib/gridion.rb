module Gridion
  autoload :GridHelper, 'gridion/grid_helper' 
end

ActiveSupport.on_load(:action_controller) do
  ActionController::Base.helper(Gridion::GridHelper)
end

