my_private_ip = my_private_ip()

elastic_addrs = all_elastic_urls_str()

template"#{node['logstash']['base_dir']}/config/spark-streaming.conf" do
  source "spark-streaming.conf.erb"
  owner node['hopslog']['user']
  group node['hopslog']['group']
  mode 0655
  variables({ 
     :my_private_ip => my_private_ip,
     :elastic_addr => elastic_addrs
  })
end

template"#{node['logstash']['base_dir']}/config/beamjobserver.conf" do
  source "beamjobserver.conf.erb"
  owner node['hopslog']['user']
  group node['hopslog']['group']
  mode 0655
  variables({
     :my_private_ip => my_private_ip,
     :elastic_addr => elastic_addrs
  })
end

template"#{node['logstash']['base_dir']}/config/beamsdkworker.conf" do
  source "beamsdkworker.conf.erb"
  owner node['hopslog']['user']
  group node['hopslog']['group']
  mode 0655
  variables({
     :my_private_ip => my_private_ip,
     :elastic_addr => elastic_addrs
  })
end

template"#{node['logstash']['base_dir']}/config/tf_serving.conf" do
  source "tf_serving.conf.erb"
  owner node['hopslog']['user']
  group node['hopslog']['group']
  mode 0655
  variables({ 
     :elastic_addr => elastic_addrs
  })
end

template"#{node['logstash']['base_dir']}/config/sklearn_serving.conf" do
  source "sklearn_serving.conf.erb"
  owner node['hopslog']['user']
  group node['hopslog']['group']
  mode 0655
  variables({
                :elastic_addr => elastic_addrs
            })
end

template"#{node['logstash']['base_dir']}/config/kube_jobs.conf" do
  source "kube_jobs.conf.erb"
  owner node['hopslog']['user']
  group node['hopslog']['group']
  mode 0655
  variables({
                :elastic_addr => elastic_addrs
            })
end

template"#{node['logstash']['base_dir']}/config/kagent.conf" do
  source "kagent.conf.erb"
  owner node['hopslog']['user']
  group node['hopslog']['group']
  mode 0655
  variables({ 
     :elastic_addr => elastic_addrs
  })
end

template"#{node['logstash']['base_dir']}/config/pipelines.yml" do
  source "pipelines.yml.erb"
  owner node['hopslog']['user']
  group node['hopslog']['group']
  mode 0655
end

template"#{node['logstash']['base_dir']}/bin/start-logstash.sh" do
  source "start-logstash.sh.erb"
  owner node['hopslog']['user']
  group node['hopslog']['group']
  mode 0750
end

template"#{node['logstash']['base_dir']}/bin/stop-logstash.sh" do
  source "stop-logstash.sh.erb"
  owner node['hopslog']['user']
  group node['hopslog']['group']
  mode 0750
end


deps = ""
if exists_local("elastic", "default") 
  deps = "elasticsearch.service"
end  
service_name="logstash"

service service_name do
  provider Chef::Provider::Service::Systemd
  supports :restart => true, :stop => true, :start => true, :status => true
  action :nothing
end

case node['platform_family']
when "rhel"
  systemd_script = "/usr/lib/systemd/system/#{service_name}.service" 
when "debian"
  systemd_script = "/lib/systemd/system/#{service_name}.service"
end

template systemd_script do
  source "#{service_name}.service.erb"
  owner "root"
  group "root"
  mode 0754
  variables({
            :deps => deps
           })
if node['services']['enabled'] == "true"
  notifies :enable, resources(:service => service_name)
end
  notifies :restart, resources(:service => service_name)
end

kagent_config service_name do
  action :systemd_reload
end  


if node['kagent']['enabled'] == "true" 
   kagent_config service_name do
     service "ELK"
     log_file "#{node['logstash']['base_dir']}/logstash.log"
   end
end

if conda_helpers.is_upgrade
  kagent_config "#{service_name}" do
    action :systemd_reload
  end
end  
