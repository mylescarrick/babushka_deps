dep 'aaibs', :env, :host, :domain, :app_user, :app_root, :key do
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

    'vhost enabled.nginx'.with(
      :app_name => 'aaibs',
      :env => env,
      :listen_host => host,
      :domain => domain,
      :domain_aliases => 'aaibs beta.aaibs.org',
      :path => app_root,
      :proxy_host => 'localhost',
      :proxy_port => 9000
    ),
  ]
end

dep 'aaibs packages' do
  requires [
    'running.nginx',
    'aaibs common packages',
  ]
end

dep 'aaibs common packages' do
  requires [
    'bundler.gem',
    'curl.lib',
  ]
end