lock '~> 3.11.0'

set :application, 'virtuatable-websockets'
set :repo_url, 'git@github.com:jdr-tools/websockets.git'
set :branch, 'master'

append :linked_files, 'config/mongoid.yml'
append :linked_files, '.env'
append :linked_dirs, 'bundle'
append :linked_dirs, 'log'