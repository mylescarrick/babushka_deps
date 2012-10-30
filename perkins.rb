dep 'perkins app', :env, :host, :domain, :app_user, :app_root, :key do
  def db_name
    YAML.load_file(app_root / 'config/database.yml')[env.to_s]['database']
  end

  requires [

    'rack app'.with(
      :env => env,
      :listen_host => host,
      :domain => domain,
      :username => app_user,
      :path => app_root,
      :data_required => 'no'
    ),

    Replace the default config with our own.
    'conversation:vhost enabled.nginx'.with(
      :app_name => 'perkins',
      :env => env,
      :listen_host => host,
      :domain => domain,
      :domain_aliases => 'perkins perkins.newington.nsw.edu.au',
      :path => app_root,
      :proxy_host => 'localhost',
      :proxy_port => 9000
    ),
  ]
end

dep 'perkins packages' do
  requires [
    'running.nginx',
    'perkins common packages',
  ]
end

dep 'perkins common packages' do
  requires [
    'bundler.gem',
    'curl.lib',
  ]
end