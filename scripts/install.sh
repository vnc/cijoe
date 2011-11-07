if [ $# -lt 2 ]
then
   echo 'Missing username and/or password.'
   echo 'USAGE:'
   echo '   install.sh username password'
   exit
fi

# Some prereqs that we'll need
sudo yum -y install git
sudo yum -y install git-svn
sudo yum -y install svn

# create a new user for cijoe to run under
sudo useradd joe

# execute the rest of the script as joe
su joe

# get our fork of cijoe
cd ~
git clone git://github.com/vnc/cijoe.git
cd ~/cijoe
gem install choice

# get brainstem
cd ~
git svn clone -s https://vivakinervecenter.jira.com/svn/PDDP/brainstem

# configure a local branch that tracks the develop branch
cd ~/brainstem
git checkout -b local/develop develop

# configure the cijoe options for brainstem
cd ~/brainstem
git config --add cijoe.runner "./surgeon deploy"
git config --add cijoe.branch local/develop
git config --add cijoe.user $1
git config --add cijoe.pass $2

echo 'cp ~/config.yml ./config' > ~/brainstem/.git/hooks/after-reset
chmod +x ~/brainstem/.git/hooks/after-reset

# Uncomment a line in the SVN config file, to allow saving pwds in plain-text.
# This allows bigtuna's svn checkout command to run w/o prompts
sed /home/joe/.subversion/config -i 's/^# store-passwords = yes/store-passwords = yes/;' 

# Generate some RSA keys w/o a passphrase for the joe user 
ssh-keygen -q -t rsa -f /home/joe/.ssh/id_rsa -N ""

# Start up cijoe
cd ~/cijoe
# nohup ruby -rubygems ~/cijoe/bin/cijoe -p 3051 ~/brainstem --svn &
thin -R cijoe.ru -p 3051 -d start