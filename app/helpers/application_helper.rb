module ApplicationHelper

  # Used to set the active navbar item
  def current_nav_target
    target = ""
    if controller_name == 'compose'
      target = 'compose'
    elsif controller_name == 'snapshots' && action_name == 'new'
      target = 'upload'
    elsif controller_name == 'snapshots' || controller_name == 'atlases'
      target = 'watch'
    elsif controller_name == 'home' && action_name == 'advanced'
      target = 'extend'
    elsif controller_name == 'sessions'
      target = 'sessions'
    end
    return target
  end

end
