module SessionHelpers

  def sign_in(user)
  end

  def current_user=(user)
  end

  def current_user
    @current_user ||= user_from_access_token
  end

  def signed_in?
    !current_user.nil? 
  end

  def sign_out
    session['access_token'] = nil
  end 

  def current_user?(user)
    user == current_user
  end

  def store_errors ( errors )
    session['errors'] = errors
  end

  def get_errors
    @errors = session['errors']
    session['errors'] = nil
    @errors
  end

  def clear_errors
    session['errors'] = nil  
  end

  def deny_access
    store_location
    redirect_to_signin_path
  end

  def store_location
    session[:return_to] = request.fullpath
  end 

  def redirect_back_or(default)
    redirect("#{session[:return_to] || default}")
    clear_return_to
  end

  def clear_return_to
    session[:return_to] = nil
  end

  private

  def user_from_access_token
    session[:access_token]
  end

  def remember_token
  end


end
