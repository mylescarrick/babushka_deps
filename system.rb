dep 'system', :host_name, :locale_name do
  requires [
    'benhoskings:set.locale'.with(locale_name),
    'core software',
    'benhoskings:hostname'.with(host_name),
    'benhoskings:secured ssh logins',
    'benhoskings:lax host key checking',
    'benhoskings:admins can sudo',
  ]
  setup {
    unmeetable! "This dep has to be run as root." unless shell('whoami') == 'root'
  }
end

dep 'user setup', :username, :key do
  username.default(shell('whoami'))
  requires [
    'benhoskings:user_exists'.with(:username => username),
    'benhoskings:passwordless ssh logins'.with(username, key),
  ]
end

dep 'core software' do
  requires {
    on :linux, 'benhoskings:sudo.bin', 'benhoskings:lsof.managed', 'benhoskings:vim.managed', 'benhoskings:curl.bin', 'benhoskings:traceroute.managed', 'benhoskings:htop.managed', 'benhoskings:iotop.managed', 'benhoskings:jnettop.managed', 'benhoskings:tmux.managed', 'benhoskings:nmap.managed', 'benhoskings:tree.managed', 'benhoskings:pv.managed'
    on :osx, 'benhoskings:nmap.managed', 'benhoskings:tree.managed', 'benhoskings:pv.managed'
  }
end