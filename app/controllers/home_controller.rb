class HomeController < ApplicationController

  include LoginRequest

  def index
  end

  def login
    if params[:domain].present? && params[:username].present? && params[:password].present?
      code = login_request(params[:domain], params[:username], params[:password])
      if code == 200
        goaway(params[:domain], params[:username], params[:password])
      else
        flash[:error] = "Access is denied due to invalid credentials"
        redirect_to :back
      end
    else
      flash[:error] = "Fill all inputs"
      redirect_to :back
    end
  end

end
