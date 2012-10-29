dep 'ssl certificate', :env, :domain, :cert_name do
  if env == 'production'
    requires 'conversation:ssl cert in place'.with(:domain => domain, :cert_name => cert_name)
  else
    requires 'benhoskings:self signed cert.nginx'.with(
      :country => 'AU',
      :state => 'NSW',
      :city => 'Sydney',
      :organisation => 'Newington College',
      :domain => domain,
      :email => 'ict@newington.nsw.edu.au'
    )
  end
end