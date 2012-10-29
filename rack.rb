dep 'rack app', :domain, :domain_aliases, :username, :path, :listen_host, :listen_port, :proxy_host, :proxy_port, :env, :nginx_prefix, :enable_http, :enable_https, :force_https, :data_required do
  username.default!(shell('whoami'))
  path.default('~/current')
  env.default(ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'production')

  requires 'benhoskings:web repo'.with(path)
  requires 'benhoskings:app bundled'.with(path, env)
  requires 'benhoskings:rack.logrotate'.with(username)
end