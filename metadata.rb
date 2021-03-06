name 'borges'
maintainer 'Udbhav Gupta'
maintainer_email 'dev@udbhavgupta.com'
license 'all_rights'
description 'Installs/Configures borges'
long_description 'Installs/Configures borges'
version '0.1.0'

depends 'apt', '~> 5.0.1'
depends 'docker', '~> 2.0'
depends 'nvm', '~> 0.1.7'
depends 'poise-python', '~> 1.5.1'
depends 'ruby_build', '~> 1.0.0'
depends 'ruby_rbenv', '~> 1.1.0'
depends 'sudo', '~> 3.3.1'
depends 'virtualbox', '~> 1.0.3'
depends 'chef_nginx', '~> 5', git: 'git@github.com:chef-cookbooks/chef_nginx.git'
depends 'htpasswd', '~> 0.2.4'
