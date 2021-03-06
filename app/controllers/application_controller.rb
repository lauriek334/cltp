# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  before_filter :wire_user

private
  
  def wire_user
    username = request.env['REMOTE_USER']
    
    # hardcode username for local dev environment where cosign is unavailable
    # comment out the line below in cosign environments and production
    username ||= 'amitava'
    
    if username.nil? || username.empty?
      render :file => "public/401.html", :status => :unauthorized
      return
    end
    
    @user = User.find_by_username username
    if @user.nil?
      render :file => "public/401.html", :status => :unauthorized 
      return
    end
    
    if session[:user].nil?
      session[:user] = @user
      @user.last_login = DateTime.now
      @user.login_count += 1
      @user.save
    end
    
    pi = request.env['PATH_INFO']
    flag = pi.nil? || pi.strip == "" || pi.strip == "/"
    if @user.primary_role != "Student" && flag
      proto = request.ssl? ? "https://" : "http://"
      redirect_to :protocol => proto, :controller => "reports", :action => "index"
    end
    
  end
  
end
