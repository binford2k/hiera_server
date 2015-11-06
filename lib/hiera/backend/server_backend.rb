require 'json'
require 'openssl'
require "net/https"   # use instead of rest-client so we can set SSL options

class Hiera
  module Backend
    class Server_backend
      def initialize
        Config[:server][:backends]  ||= Config[:backends]
        Config[:server][:hierarchy] ||= Config[:hierarchy]
        Config[:server][:port]      ||= '8141'

        # I think this connection can be reused like this. If not, move it to the query and make it local
        @http = Net::HTTP.new(Config[:server][:server], Config[:server][:port])

        if Config[:server][:ssl]
          @http.use_ssl = true
          @http.verify_mode = OpenSSL::SSL::VERIFY_PEER

          store = OpenSSL::X509::Store.new
          store.add_cert(OpenSSL::X509::Certificate.new(File.read(Config[:server][:ca_cert])))
          @http.cert_store = store

          @http.key = OpenSSL::PKey::RSA.new(File.read(Config[:server][:public_key]))
          @http.cert = OpenSSL::X509::Certificate.new(File.read(Config[:server][:private_key]))
        else
          @http.use_ssl = false
        end

        debug ("Loaded HieraServer Backend")
      end

      def debug(msg)
        Hiera.debug("[HieraServer]: #{msg}")
      end

      def warn(msg)
        Hiera.warn("[HieraServer]:  #{msg}")
      end

      def lookup(key, scope, order_override, resolution_type, context)
        debug("Looking up '#{key}', resolution type is #{resolution_type}")

        path    = "/#{resolution_type.to_s}/#{key}"
        request = Net::HTTP::Post.new(path, initheader = {'Content-Type' =>'application/json'})

        request.body = {
          "scope"              => scope,
          "backends"           => Config[:server][:backends],
          "hierarchy"          => Config[:server][:hierarchy],
          "hierarchy_override" => Config[:server][:hierarchy_override],
        }.to_json

        # make the request
        response = JSON.parse(@http.request(request).body)

        if response.keys.include? 'value'
          response['value']
        else
          warn response['error']
          debug response['trace']
        end
      end

    end
  end
end
