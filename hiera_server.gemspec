$:.unshift File.expand_path("../lib", __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name              = "hiera_server"
  s.version           = '0.0.1'
  s.date              = Date.today.to_s
  s.summary           = "Provides a remote server for Hiera lookups and a backend client."
  s.homepage          = "https://github.com/binford2k/hiera_server"
  s.license           = 'Apache 2.0'
  s.email             = "binford2k@gmail.com"
  s.authors           = ["Ben Ford"]
  s.has_rdoc          = false
  s.require_path      = "lib"
  s.executables       = %w( hiera_server )

  s.files             = %w( README.md LICENSE )
  s.files            += Dir.glob("lib/**/*")
  s.files            += Dir.glob("bin/**/*")
  s.files            += Dir.glob("doc/**/*")

  s.add_dependency      "sinatra", ">= 1.3"
  s.add_dependency      "json_pure"

  s.description       = <<-desc
  Hiera Server separates the query and the data retrieval into separate processes.
  The *server* portion runs on a remote machine and uses any configured Hiera backend
  to retrieve data. The *client* portion simply runs as a backend on the local machine.

  Facilities are provided to configure the data lookup on the server from either end.
  See README.md for more information.
  desc
end
