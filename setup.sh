#!/bin/bash
source botos.env
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BOTOS_PATH="$HOME/botos"
cd ~

# install prerequisites
sudo apt update
sudo apt install libpq-dev postgresql postgresql-contrib nginx python3-pip python3-dev

# setup firewall (optional?)
sudo apt install ufw
sudo ufw enable
sudo ufw allow 80
sudo ufw allow 8000

# compile pyenv
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
cd ~/.pyenv && src/configure && make -C src

# set up shell env for pyenv
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.profile
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.profile
echo 'eval "$(pyenv init -)"' >> ~/.profile

echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile
echo 'eval "$(pyenv init -)"' >> ~/.bash_profile

echo 'export PATH=$HOME/bin:$HOME/.local/lib/python3-5/site-packages:$HOME/.local/bin:/usr/bin:/usr/local/bin:/usr/sbin:/usr/local/sbin:$PATH' >> ~/.bashrc
echo 'export PATH=$HOME/bin:$HOME/.local/lib/python3-5/site-packages:$HOME/.local/bin:/usr/bin:/usr/local/bin:/usr/sbin:/usr/local/sbin:$PATH' >> ~/.profile
echo 'export PATH=$HOME/bin:$HOME/.local/lib/python3-5/site-packages:$HOME/.local/bin:/usr/bin:/usr/local/bin:/usr/sbin:/usr/local/sbin:$PATH' >> ~/.bash_profile

source ~/.bashrc

# install python build dependencies
sudo apt-get update; sudo apt-get install make build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev openssl

pyenv install 3.5.5 # 3.5.5 is the only version of Python 3.5 that supports the newer versions of OpenSSL
pyenv global system

pip install pipenv

# now we can setup the postgresql db
sudo -u postgres psql -c "CREATE DATABASE $BOTOS_DATABASE_NAME"
sudo -u postgres psql -c "CREATE DATABASE $BOTOS_TEST_DATABASE_NAME"
# you can change the password to the db, just make sure you also change it in botos.env
sudo -u postgres -H -- psql << EOF
CREATE USER $BOTOS_DATABASE_USERNAME WITH PASSWORD $BOTOS_DATABASE_PASSWORD;
ALTER ROLE $BOTOS_DATABASE_USERNAME SET client_encoding TO 'utf-8';
ALTER ROLE $BOTOS_DATABASE_USERNAME SET default_transaction_isolation TO 'read committed';
ALTER ROLE $BOTOS_DATABASE_USERNAME SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE $BOTOS_DATABASE_NAME TO $BOTOS_DATABASE_USERNAME;
EOF

cd ~/botos
pipenv install
pipenv install pandas numpy # dev dependency to upload users
cp "$SCRIPT_DIR/botos.env" ~/botos/botos.env

pipenv run << EOF
# export env vars
set -o allexport
source ~/botos/botos.env
set +o allexport

python manage.py makemigrations
python manage.py migrate

mkdir -p botos/static
python manage.py collectstatic

# create the superuser
echo "from django.contrib.auth import get_user_model; User=get_user_model(); User.objects.create_super_user('$BOTOS_DATABASE_USERNAME','electionsemail@gmail.com','$BOTOS_DATABASE_PASSWORD')" | python manage.py shell
EOF

# gunicorn setup
sudo cp "$SCRIPT_DIR/botos-gunicorn.socket" /etc/systemd/system
sudo sed -e "s|<botos-path>|$BOTOS_PATH|g" -e "s|<venv-path>|$(pipenv --venv)|g" "$SCRIPT_DIR/botos-gunicorn.service"> /etc/systemd/system/botos-gunicorn.service
sudo systemctl enable --now botos-gunicorn.socket

# setup nginx
sudo mkdir -p /etc/nginx/sites-available
sudo sed -e "s|<botos-path>|$BOTOS_PATH|g" "$SCRIPT_DIR/botos" > /etc/nginx/sites-available/botos
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/botos /etc/nginx/sites-enabled
sudo systemctl restart nginx

# upload the users to the database
cd "$SCRIPT_PATH/xlsx"
sh convertcsv.sh
cd split
python merge-users.py
cp userdata.csv $BOTOS_PATH
cp "$SCRIPT_PATH/upload_users.py" $BOTOS_PATH
cd $BOTOS_PATH
echo "exec(open(upload_users.py).read())" | python manage.py shell
