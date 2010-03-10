require 'sinatra/base'

class StatusEcho < Sinatra::Base

  set :root, File.join(File.dirname(__FILE__), '..')

  helpers do

    def echo_it
      code = params[:captures].first.to_i

      if code == 200
        'all good'
      else
        halt code, 'you asked for it'
      end

    end

  end

  get(%r{/.*?(\d{3}).*}){ echo_it }
  post(%r{/.*?(\d{3}).*}){ echo_it }
end

