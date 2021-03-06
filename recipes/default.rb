#
# Cookbook Name:: borges
# Recipe:: default
#
# Copyright (c) 2017 Udbhav Gupta, All Rights Reserved.

include_recipe "apt"

# add relevant repositories for apt
apt_repository 'yarn' do
  uri 'https://dl.yarnpkg.com/debian/'
  components ['main']
  distribution 'stable'
  key 'https://dl.yarnpkg.com/debian/pubkey.gpg'
  action :add
end

apt_repository 'oracle-virtualbox' do
  uri 'http://download.virtualbox.org/virtualbox/debian'
  key 'https://www.virtualbox.org/download/oracle_vbox_2016.asc'
  distribution node['lsb']['codename']
  components ['contrib']
end

apt_repository 'r-base' do
  uri 'http://cran.rstudio.com/bin/linux/ubuntu'
  key 'E084DAB9'
  keyserver 'keyserver.ubuntu.com'
  distribution "#{node['lsb']['codename']}/"
end

# essential tools

packages = [
  'curl',
  'libcurl4-openssl-dev', # for packages in R
  'git',
  'tmux',
  'zsh',
  'xclip',

  # emacs
  'emacs', 'ispell', 'ess',

  'vagrant',
  'yarn',
  'mosh',

  # virtualbox
  'dkms', 'virtualbox-5.1'
]

packages.each do |pkg|
  package pkg do
    action :install
  end
end

python_runtime '2'

# create our admins
ADMIN_GROUP = 'sysadmin'
group ADMIN_GROUP

admins = data_bag('admins')

admins.each do |login|
  admin = data_bag_item('admins', login)
  home = "/home/#{login}"

  user(login) do
    home home
    manage_home true
    gid ADMIN_GROUP
    shell "/bin/zsh"
    password admin['password']
  end

  htpasswd "/etc/nginx/htpassword" do
    user login
    password admin['htpasswd']
  end
end

node.default['authorization']['sudo']['groups'] = [ADMIN_GROUP]
include_recipe "sudo"

DEFAULT_USER = node['borges']['default_user']
DEFAULT_HOME = "/home/#{DEFAULT_USER}"

default_user_bag = data_bag_item('admins', DEFAULT_USER)

# ssh keys
directory "#{DEFAULT_HOME}/.ssh" do
  owner DEFAULT_USER
  mode '0700'
  action :create
end

file "#{DEFAULT_HOME}/.ssh/id_rsa" do
  content default_user_bag['id_rsa']
  mode '0600'
  owner DEFAULT_USER
end

file "#{DEFAULT_HOME}/.ssh/id_rsa.pub" do
  content default_user_bag['id_rsa.pub']
  mode '0644'
  owner DEFAULT_USER
end

file "#{DEFAULT_HOME}/.ssh/authorized_keys" do
  content default_user_bag['id_rsa.pub']
  mode '0600'
  owner DEFAULT_USER
end

# Disable strict host checking for github
file "#{DEFAULT_HOME}/.ssh/config" do
  content "Host github.com\n\tStrictHostKeyChecking no\n"
end

# oh my zsh
execute "oh-my-zsh" do
  command "sh -c \"$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)\" || true"
  user DEFAULT_USER
  environment ({'HOME' => DEFAULT_HOME})
  not_if { Dir.exist?("#{DEFAULT_HOME}/.oh-my-zsh") }
end

# dotfile configs
git "#{DEFAULT_HOME}/dotfiles" do
  repository node['borges']['dotfiles_repo']
  revision 'master'
  action :sync
  user DEFAULT_USER
end

links = [".emacs", ".emacs-packages", ".zshrc", ".tmux.conf", ".gitignore_global"]
links.each do |l|
  link "#{DEFAULT_HOME}/#{l}" do
    to "#{DEFAULT_HOME}/dotfiles/#{l}"
  end
end

git "#{DEFAULT_HOME}/borges" do
  repository node['borges']['borges_repo']
  revision 'master'
  action :sync
  user DEFAULT_USER
end

link "/root/borges" do
  to "#{DEFAULT_HOME}/borges"
end

GIT_CONFIGS = {
  "user.name" => default_user_bag['name'],
  "user.email" => default_user_bag['email'],
  "push.default" => "simple",
  "core.excludesfile" => "~/.gitignore_global",
}

GIT_CONFIGS.each do |k,v|
  execute "git config --global #{k} #{v}" do
    user DEFAULT_USER
    environment ({'HOME' => DEFAULT_HOME})
  end
end

RUBY_VERSION = '2.4.0'
ENV['RUBY_CONFIGURE_OPTS'] = '--disable-install-doc'

node.default['rbenv']['user_installs'] = [
  { 'user'    => DEFAULT_USER,
    'rubies'  => [RUBY_VERSION],
    'global'  => RUBY_VERSION,
    'gems'    => {
      RUBY_VERSION    => [
        { 'name'    => 'bundler' }
      ],
    }
  }
]

node.default['rbenv']['rubies'] = [ RUBY_VERSION ]

include_recipe "ruby_build"
include_recipe "ruby_rbenv::user"

# nodejs
include_recipe 'nvm'
nvm_install '6.9.4' do
  user DEFAULT_USER
  group ADMIN_GROUP
  from_source false
  alias_as_default true
  action :create
end

# docker
docker_service 'default' do
  action [:create, :start]
end

# docker compose
DOCKER_COMPOSE_LOCATION = "/usr/local/bin/docker-compose"

execute "install docker-compose" do
  command "curl -L \"https://github.com/docker/compose/releases/download/1.10.0/docker-compose-$(uname -s)-$(uname -m)\" -o #{DOCKER_COMPOSE_LOCATION}"
  not_if { File.exist?(DOCKER_COMPOSE_LOCATION) }
end

file DOCKER_COMPOSE_LOCATION do
  mode "0755"
end

# add user to docker group to avoid sudo need
group 'docker' do
  action :modify
  members DEFAULT_USER
  append true
end

# nginx
include_recipe 'chef_nginx'

# public html directory
PUBLIC_DIR = "#{DEFAULT_HOME}/public_html"
directory PUBLIC_DIR do
  recursive true
  user DEFAULT_USER
end

# sites for projects
template '/etc/nginx/sites-available/projects' do
  source 'nginx.erb'
  variables(
    {
      projects: node['borges']['projects'],
      hostname: node['borges']['hostname'],
      public_dir: PUBLIC_DIR,
    }
  )
end

nginx_site "projects"

# emacs daemon
SYSTEMD_DIR = "/etc/systemd/system"
directory SYSTEMD_DIR do
  recursive true
end

template "#{SYSTEMD_DIR}/emacs@.service" do
  source 'emacs.service'
end

service "emacs@#{DEFAULT_USER}.service" do
  action [:enable, :start]
end

USER_BIN = "#{DEFAULT_HOME}/bin"
directory USER_BIN do
  recursive true
  owner DEFAULT_USER
end

# pbcopy-remote and pbpaste-remote
template "#{USER_BIN}/pbcopy-remote" do
  source 'pbcopy-remote.sh'
  owner DEFAULT_USER
  mode "0755"
end

template "#{USER_BIN}/pbpaste-remote" do
  source 'pbpaste-remote.sh'
  owner DEFAULT_USER
  mode "0755"
end


# R Language
package 'r-base' do
  action :install
end

python_packages = [
  'glances', # sysadmin
  'flake8', # linting
]

python_packages.each do |pkg|
  python_package pkg
end
