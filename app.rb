require 'sinatra'
require 'twilio-ruby'
require 'net/http'

set :twilio_sid, ENV['TWILIO_SID']
set :twilio_token, ENV['TWILIO_TOKEN']
set :twilio_phone_number, ENV['TWILIO_PHONE_NUMBER']

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end

  def send_kitten(phone_number, user_message)
    send_sms phone_number, "#{user_message}: #{random_emergency_kitten}"
  end

  def random_emergency_kitten
    response = Net::HTTP.get_response(URI('http://emergencykitten.com/img/random'))
    response['Location']
  end

  def send_sms(phone_number, sms_message)
    if settings.twilio_sid && settings.twilio_token
      client = Twilio::REST::Client.new settings.twilio_sid, settings.twilio_token
      client.account.messages.create body: sms_message,
                                     to:   phone_number,
                                     from: settings.twilio_phone_number
    end
  rescue Twilio::REST::RequestError => e
    # Ignore unverified errors - you can only send to your own phone number on a
    # trial account
    raise unless e.message =~ /unverified/
  end
end

get '/' do
  erb :form
end

post '/' do
  @phone_number = params[:phone_number]
  send_kitten @phone_number, params[:message]
  erb :sent
end
