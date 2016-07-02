module LoginRequest

  def login_request(domain, user, password)
    response = HTTParty.post('https://www.schoolbaseonline.biz/Logon.aspx?ReturnUrl=%2f',
      {
        'ctl00$ContentPlaceHolder1$txtDomain': domain,
        'ctl00$ContentPlaceHolder1$txtUser': user,
        'ctl00$ContentPlaceHolder1$txtPassword': password
      }
    )
    response.code
  end

  def login
    response = HTTParty.get('https://www.schoolbaseonline.biz/Logon.aspx?ReturnUrl=%2f',
      {
        'ctl00$ContentPlaceHolder1$txtDomain': 'domain',
        'ctl00$ContentPlaceHolder1$txtUser': 'foo@bar.com',
        'ctl00$ContentPlaceHolder1$txtPassword': '1323'
      }
    )
    response.code
  end

  def goaway(domain, user, password)
    redirect_to "https://www.schoolbaseonline.biz/Logon.aspx?ReturnUrl=%2f&ctl00$ContentPlaceHolder1$txtDomain=#{domain}&ctl00$ContentPlaceHolder1$txtUser=#{user}&ctl00$ContentPlaceHolder1$txtPassword=#{password}"
  end

end