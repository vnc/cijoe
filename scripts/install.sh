if [ $# -lt 2 ]
then
   echo 'Missing username and/or password.'
   echo 'USAGE:'
   echo '   install.sh username password'
   exit
fi

# Some prereqs that we'll need
sudo yum -y install git svn git-svn
sudo yum -y install openssl-devel libtool 
                                  
# make /tmp publicly accessible (needed for successsful non-sudo rvm install)
sudo chmod -R ugo+rwx /tmp   
                      
# create a new user for cijoe to run under
sudo useradd joe      

sudo cat > rvm_setup.sh <<END_OF_SCRIPT
# Install RVM
bash < <(curl -s https://rvm.beginrescueend.com/install/rvm)
echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" # Load RVM function' >> ~/.bash_profile
source ~/.bash_profile

# install ruby-1.9.2-p290 using RVM
rvm pkg install openssl
rvm install 1.9.2-p290
rvm use ruby-1.9.2-p290

# setup gemsets and globals gems
rvm gemset use global
gem install bundler
rvm gemset create cijoe
rvm gemset use cijoe

# setup rvm options
echo 'export rvm_trust_rvmrcs_flag=1' >> /home/brainstem/.rvmrc
END_OF_SCRIPT       

sudo mv rvm_setup.sh /home/joe/rvm_setup.sh
sudo chown joe:joe /home/joe/rvm_setup.sh
sudo chmod ug+x /home/joe/rvm_setup.sh     

# execute the rest of the script as joe
su joe

# Generate some RSA keys w/o a passphrase for the joe user 
ssh-keygen -q -t rsa -f /home/joe/.ssh/id_rsa -N ""

# install/configure rvm
cd ~
./rvm_setup.sh         

# Uncomment a line in the SVN config file, to allow saving pwds in plain-text.
# This allows bigtuna's svn checkout command to run w/o prompts
sed /home/joe/.subversion/config -i 's/^# store-passwords = yes/store-passwords = yes/;' 

# get our fork of cijoe
cd ~
git clone git://github.com/vnc/cijoe.git
                
# install cijoe deps
cd ~/cijoe
bundle install

# get brainstem
cd ~
git svn clone -s https://vivakinervecenter.jira.com/svn/PDDP/brainstem

# configure a local branch that tracks the develop branch
cd ~/brainstem
git checkout -b local/develop develop

# configure the cijoe options for brainstem
cd ~/brainstem
git config --add cijoe.runner "bundle install && ./surgeon deploy"
git config --add cijoe.branch local/develop
git config --add cijoe.user $1
git config --add cijoe.pass $2

# place the real config.yml file you want to use for newly-deployed brainstem
# instances at ~/config.yml

# set up reverse proxy config in apache vhost

echo 'cp ~/config.yml ./config' > ~/brainstem/.git/hooks/after-reset
chmod +x ~/brainstem/.git/hooks/after-reset

# Start up cijoe
cd ~
nohup ruby ~/cijoe/bin/cijoe -p 3051 ~/brainstem --svn &
