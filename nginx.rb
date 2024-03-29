meta :nginx do
  accepts_list_for :source

  def nginx_bin;    nginx_prefix / "sbin/nginx" end
  def nginx_pid;    nginx_prefix / 'logs/nginx.pid' end
  def cert_path;    nginx_prefix / "conf/certs" end
  def nginx_conf;   nginx_prefix / "conf/nginx.conf" end
  def vhost_conf;   nginx_prefix / "conf/vhosts/#{domain}.conf" end
  def vhost_common; nginx_prefix / "conf/vhosts/#{domain}.common" end
  def vhost_link;   nginx_prefix / "conf/vhosts/on/#{domain}.conf" end

  def upstream_name
    "#{domain}.upstream"
  end
  def unicorn_socket
    path / 'tmp/sockets/unicorn.socket'
  end
  def nginx_running?
    shell? "netstat -an | grep -E '^tcp.*[.:]80 +.*LISTEN'"
  end
  def restart_nginx
    if nginx_running?
      log_shell "Restarting nginx", "#{nginx_bin} -s reload", :sudo => true
      sleep 1 # The reload just sends the signal, and doesn't wait.
    end
  end
end

dep 'vhost enabled.nginx', :app_name, :env, :domain, :domain_aliases, :path, :listen_host, :listen_port, :proxy_host, :proxy_port, :nginx_prefix do
  requires 'vhost configured.nginx'.with(app_name, env, domain, domain_aliases, path, listen_host, listen_port, proxy_host, proxy_port, nginx_prefix)
  met? { vhost_link.exists? }
  meet {
    sudo "mkdir -p #{nginx_prefix / 'conf/vhosts/on'}"
    sudo "ln -sf '#{vhost_conf}' '#{vhost_link}'"
  }
  after { restart_nginx }
end

dep 'vhost configured.nginx', :app_name, :env, :domain, :domain_aliases, :path, :listen_host, :listen_port, :proxy_host, :proxy_port, :nginx_prefix do
  env.default!('production')
  domain_aliases.default('').ask('Domains to alias (no need to specify www. aliases)')
  listen_host.default!('[::]')
  listen_port.default!('80')
  proxy_host.default('localhost')
  proxy_port.default('8000')

  def www_aliases
    "#{domain} #{domain_aliases}".split(/\s+/).reject {|d|
      d[/^\*\./] || d[/^www\./]
    }.map {|d|
      "www.#{d}"
    }
  end
  def server_names
    [domain].concat(
      domain_aliases.to_s.split(/\s+/)
    ).concat(
      www_aliases
    ).uniq
  end

  path.default("~#{domain}/current".p) if shell?('id', domain)
  nginx_prefix.default!('/opt/nginx')

  requires 'configured.nginx'.with(nginx_prefix)
  requires 'benhoskings:unicorn configured'.with(path)

  met? {
    Babushka::Renderable.new(vhost_conf).from?(dependency.load_path.parent / "nginx/#{app_name}_vhost.conf.erb")
  }
  meet {
    sudo "mkdir -p #{nginx_prefix / 'conf/vhosts'}"
    render_erb "nginx/#{app_name}_vhost.conf.erb", :to => vhost_conf, :sudo => true
  }
end

dep 'http basic logins.nginx', :nginx_prefix, :domain, :username, :pass do
  nginx_prefix.default!('/opt/nginx')
  met? { shell("curl -I -u #{username}:#{pass} #{domain}").val_for('HTTP/1.1')[/^[25]0\d\b/] }
  meet { append_to_file "#{username}:#{pass.to_s.crypt(pass)}", (nginx_prefix / 'conf/htpasswd'), :sudo => true }
  after { restart_nginx }
end

dep 'running.nginx', :nginx_prefix do
  requires 'configured.nginx'.with(nginx_prefix), 'startup script.nginx'.with(nginx_prefix)
  met? {
    nginx_running?.tap {|result|
      log "There is #{result ? 'something' : 'nothing'} listening on port 80."
    }
  }
  meet {
    shell 'initctl start nginx'
  }
end

dep 'startup script.nginx', :nginx_prefix do
  requires 'conversation:nginx.src'.with(:nginx_prefix => nginx_prefix)
  met? {
    shell('initctl list').split("\n").grep(/^nginx\b/).any?
  }
  meet {
    render_erb 'nginx/nginx.init.conf.erb', :to => '/etc/init/nginx.conf'
  }
end

dep 'configured.nginx', :nginx_prefix do
  def nginx_conf
    nginx_prefix / "conf/nginx.conf"
  end
  nginx_prefix.default!('/opt/nginx') # This is required because nginx.src might be cached.
  requires [
    'conversation:nginx.src'.with(:nginx_prefix => nginx_prefix),
    'benhoskings:www user and group',
    'benhoskings:nginx.logrotate'
  ]
  met? {
    Babushka::Renderable.new(nginx_conf).from?(dependency.load_path.parent / "nginx/nginx.conf.erb")
  }
  meet {
    render_erb 'nginx/nginx.conf.erb', :to => nginx_conf, :sudo => true
  }
end
