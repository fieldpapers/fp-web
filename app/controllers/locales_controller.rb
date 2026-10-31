class LocalesController < ApplicationController
  def update
    cookies.permanent[:locale] = params[:locale]
    redirect_back_or_to root_path, allow_other_host: false
  end
end
