module AuthHelpers

  def ldap_authenticate(login, pass)
    #return false if login.empty? or pass.empty?

    conn = Net::LDAP.new  :host => SETTINGS.ldap[:host],
                          :port => 389,
                          :auth => { :username => "#{SETTINGS.ldap[:bind]}",
                                     :password => "#{SETTINGS.ldap[:pass]}",
                                     :method => :simple }
    if conn.bind_as(  :base => SETTINGS.ldap[:base],
                      :filter => "(samaccountname=#{login})",
                      :password => pass)
      session[:access_token] = login
      return login
    else
      store_errors "username or password may be incorrect, please try again"
      return false
    end

    rescue Net::LDAP::LdapError => e
      return false
  end

  # cas authentication with proxy ticket
  def cas_proxy_authentication(request, session)
    if !cas_logged_in?(request, session)
      cas_base_url = SETTINGS.cas[:host]
      client = CASClient::Client.new(
       :cas_base_url => cas_base_url
      )
      client.configure(
        :username_session_key => :access_token,
        :cas_base_url => cas_base_url
      )
      service_url = read_service_url(request)
      url = client.add_service_to_login_url(service_url)
      redirect url
      return true
    end
  end

  def cas_logged_in?(request, session)
    session[:cas_ticket] && !session[:cas_ticket].empty?
  end

  def process_cas_login(request, session)
    if request[:ticket] && request[:ticket] != session[:ticket]
      cas_base_url = SETTINGS.cas[:host]
      client = CASClient::Client.new(
       :cas_base_url => cas_base_url
      )
      service_url = read_service_url(request)
      st = read_ticket(request[:ticket], service_url)

      client.validate_service_ticket(st)

      if st.success
        session[:cas_ticket] = st.ticket
        session[:cas_user] = st.user
        session[:access_token] = st.user
      else
        raise "Service Ticket validation failed! #{st.failure_code} - #{st.failure_message}"
      end
      return true
    end
  end

  # cas authenticate with a one time use service ticket as a example
  def cas_authenticate(username,password,request)
     cas_base_url = SETTINGS.cas[:host]
     client = CASClient::Client.new(
      :cas_base_url => cas_base_url
     )

     service_url = read_service_url(request)    

     # get login ticket for cas
     session["cas_lt"] = client.request_login_ticket

     credentials = { 
       :username => username,
       :password => password,
       :service => service_url,
       :lt => session["cas_lt"]
     }

     # send login data to cas server
     uri = URI.parse("#{cas_base_url}/login") unless uri.kind_of? URI
     req = Net::HTTP::Post.new(uri.path)
     req.use_ssl = (uri.scheme == 'https')
     if req.use_ssl?
       req.verify_mode = OpenSSL::SSL::VERIFY_NONE
     end
     req.set_form_data(credentials)
     cas_login = Net::HTTP.start(uri.hostname, uri.port) do |http|
       http.request(req)
     end

     response = CASClient::LoginResponse.new(cas_login)
     session[:cas_ticket] = response.ticket

     # we create a ServiceTicket object out of this
     st = read_ticket(response.ticket, service_url)

     # at this point we get a service ticket and we validate it
     validation = client.validate_service_ticket(st) unless st.nil?

     if validation.success
       session[:access_token] =  st.user
     end unless validation.nil?

     return session[:access_token]
  end

  # This is for ldap redirection to send to login page
  def ldap_authorize!(error)
    if signed_in? == false
      store_location
      store_errors "authorized required, please login to continue"
      redirect("#{error}")
    else
      return true
    end
  end


  # check if already signed in or if authorized
  def protected!(auth_method,request,session)
    unless ( signed_in? or authorized?(auth_method,request,session) )
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end
  end

  def authorized?(auth_method,request,session)
    @auth ||= Rack::Auth::Basic::Request.new(request.env)
    case auth_method
      when "ldap"
        @auth.provided? and @auth.basic? and @auth.credentials and login_attempt=ldap_authenticate(@auth.credentials[0],@auth.credentials[1])
        if @auth.provided? and @auth.basic? and @auth.credentials
          return true if login_attempt==@auth.credentials[0]
        else return false
        end
      when "cas_service"
          if @auth.provided? and @auth.basic? and @auth.credentials
            login_attempt=cas_authenticate(@auth.credentials[0],@auth.credentials[1],request)
          end
          if login_attempt
            return true if login_attempt==@auth.credentials[0] else return false
          end
      when "cas_proxy"
        if ( process_cas_login(request, session) or cas_proxy_authentication(request,session)) 
          return true
        else return false
        end
      else
        return false
    end
  end

  private
  def read_service_url(request)
    service_url = url(request.url)
    if request.GET
      params = request.GET.dup
      params.delete(:ticket)
      if params
        [service_url, Rack::Utils.build_nested_query(params)].join('?')
      end
    end
    return service_url
  end

  def read_ticket(ticket_str, service_url)
    return nil unless ticket_str and !ticket_str.empty?
    if ticket_str =~ /^PT-/
      CASClient::ProxyTicket.new(ticket_str, service_url)
    else
      CASClient::ServiceTicket.new(ticket_str, service_url)
    end
  end

end


