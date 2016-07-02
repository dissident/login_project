require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
# require 'mina/whenever'
# require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
# require 'mina/rvm'    # for rvm support. (http://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

# Multistaging deploy ( `mina deploy to=production` ):
# case ENV['to']

# default settings (staging)

set :domain, 'phosphorus.locum.ru' # 'craftup.ru'
set :user, 'hosting_graveman'
set :name, 'graveman'
set :project_name, 'login'
set :deploy_to, "/home/#{ user }/projects/#{ project_name }"
set :branch, 'master'
set :rails_env, 'production'

set :repository, 'git@github.com:dissident/login_project.git'
set :forward_agent, true

# ! probably you will need add RSA key of repository server manually once before deploy
# ! just enter your server with `ssh user@server -A` and clone your repo to any folder

# For system-wide RVM install.
#   set :rvm_path, '/usr/local/rvm/bin/rvm'

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['config/database.yml', 'log', 'public/assets', 'public/uploads', 'public/content', 'db/maket_backup']

# Optional settings:
#   set :user, 'foobar'    # Username in the server to SSH to.
#   set :port, '30000'     # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.
task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use[ruby-2.2.2@default]'
end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task setup: :environment do
  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/log"]

  queue! %[mkdir -p "#{deploy_to}/#{shared_path}/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/#{shared_path}/config"]

  queue! %[mkdir -p "#{deploy_to}/shared/public/uploads"]
  queue! %[mkdir -p "#{deploy_to}/shared/public/content"]
  queue! %[mkdir -p "#{deploy_to}/shared/public/assets"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/public"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/public/uploads"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/public/content"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/public/assets"]

  queue! %[touch "#{deploy_to}/#{shared_path}/config/database.yml"]
  queue  %[echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/config/database.yml'."]

  queue! %[touch "#{deploy_to}/#{shared_path}/config/application.yml"]
  queue  %[echo "-----> Be sure to edit '#{deploy_to}/#{shared_path}/config/application.yml'."]
end

desc "Deploys the current version to the server."
task deploy: :environment do
  deploy do
    # Put things that will set up an empty directory into a fully set-up
    # instance of your project.
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    # invoke :'bundle:install'
    queue  "rvm use 2.2.2 do bundle install --path=~/projects/#{project_name}/shared/gems --without development test"
    # invoke :'rails:db_migrate'
    queue  "rvm use 2.2.2 do bundle exec rake db:migrate RAILS_ENV=production"
    # invoke :'rails:assets_precompile'
    queue  "rvm use 2.2.2 do bundle exec rake assets:precompile RAILS_ENV=production"
    invoke :'deploy:cleanup'

    to :launch do
      queue "mkdir -p #{deploy_to}/#{current_path}/tmp/"
      # queue "touch #{deploy_to}/#{current_path}/tmp/restart.txt"
      # invoke :'whenever:update'
      queue "kill -QUIT `cat /var/run/unicorn/#{user}/#{project_name}.#{name}.pid`"
      queue "rvm use 2.2.2 do bundle exec unicorn_rails -Dc /etc/unicorn/#{project_name}.#{name}.rb"
    end

    to :clean do
    end
  end
end

namespace :seed do

  desc "Create seed data in database"
  task go: :environment do
    queue "cd #{deploy_to}/current"
    queue "rvm use 2.2.2 do bundle exec rake db:migrate VERSION=0 RAILS_ENV=production"
    queue "rvm use 2.2.2 do bundle exec rake db:migrate RAILS_ENV=production"
    queue "rvm use 2.2.2 do bundle exec rake db:seed RAILS_ENV=production"
  end

end


namespace :unicorn do

  set :unicorn_pid, "#{app_path}/tmp/pids/unicorn.pid"
  set :start_unicorn, %{
    cd #{app_path}
    bundle exec unicorn -c #{app_path}/config/unicorn/#{rails_env}.rb -E #{rails_env} -D
  }

  desc "Start unicorn"
  task :start => :environment do
    queue 'echo "-----> Start Unicorn"'
    queue! start_unicorn
  end

  desc "Stop unicorn"
  task :stop do
    queue 'echo "-----> Stop Unicorn"'
    queue! %{
      test -s "#{unicorn_pid}" && kill -QUIT `cat "#{unicorn_pid}"` && echo "Stop Ok" && exit 0
      echo >&2 "Not running"
    }
  end

  desc "Restart unicorn using 'upgrade'"
  task :restart => :environment do
    invoke 'unicorn:stop'
    invoke 'unicorn:start'
  end
end

# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers

