require 'rubygems'
require 'sinatra/base'
require 'json'

require 'hiera'

class HieraServer < Sinatra::Base

  get '/' do
    raise Sinatra::NotFound
  end

  post '/:type/:key' do |type, key|
    begin
      request.body.rewind
      body  = JSON.parse(request.body.read)
      hiera = Hiera.new(:config => munged_config(body))

      if type == 'merge'
        value = hiera.lookup(key, nil, body['scope'], nil, body['merge'])
      else
        value = hiera.lookup(key, nil, body['scope'], nil, type.to_sym)
      end
    # Must rescue Exception because that's what Hiera raises.
    rescue Exception => e
      binding.pry if $config[:server][:debug]
      raise e if [Interrupt, SignalException].include? e.class
      {
        'error' => e.message,
        'trace' => e.backtrace,
      }.to_json
    end

    {'value' => value}.to_json
  end

  not_found do
    halt 404, "You shall not pass! (page not found)\n"
  end

  helpers do
    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end  #end protected!

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials &&
      @auth.credentials == [$config['user'],$config['pass']]
    end  #end authorized?

    def munged_config(data)
      config = $config.dup

      # let the client configure the backend to use
      config[:backends] = data['backends'] if data.include? 'backends'

      # munge the hierarchy as needed
      case data['hierarchy_override']
      when 'prepend'
        config[:hierarchy].unshift data['hierarchy']
      when 'append'
        config[:hierarchy] << data['hierarchy']
      when 'replace'
        config[:hierarchy] = data['hierarchy']
      end

      # now copy in arbitrary config settings that we're not already handling
      config[:server] = data.reject {|item| ['backend', 'hierarchy', 'scope', 'merge'].include? item }

      config
    end

  end
end
