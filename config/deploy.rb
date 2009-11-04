set :application, "f0rk.me"
set :repository,  "git://github.com/mattmatt/relink.git"

set :scm, :git
set :use_sudo, false
set :deploy_to, "/var/www/#{application}"
ssh_options[:forward_agent] = true
default_run_options[:pty] = true
set :deploy_via, :remote_cache

role :web, "www.f0rk.me"
role :app, "www.f0rk.me"
role :db,  "www.f0rk.me", :primary => true

namespace :deploy do
  task(:start) {}
  task(:stop) {}
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end