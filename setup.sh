#!/bin/bash
source botos.env
SCRIPT_DIR="$HOME/botos-setup-scripts"
BOTOS_PATH="$HOME/botos"
cd ~

# install prerequisites
sudo apt update
sudo apt install libpq-dev postgresql postgresql-contrib nginx python3-pip python3-dev python3

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
export PATH=$HOME/.pyenv/bin:$HOME/bin:$HOME/.local/lib/python3-5/site-packages:$HOME/.local/bin:/usr/bin:/usr/local/bin:/usr/sbin:/usr/local/sbin:$PATH

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
CREATE USER $BOTOS_DATABASE_USERNAME WITH PASSWORD '$BOTOS_DATABASE_PASSWORD';
ALTER ROLE $BOTOS_DATABASE_USERNAME SET client_encoding TO 'utf-8';
ALTER ROLE $BOTOS_DATABASE_USERNAME SET default_transaction_isolation TO 'read committed';
ALTER ROLE $BOTOS_DATABASE_USERNAME SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE $BOTOS_DATABASE_NAME TO $BOTOS_DATABASE_USERNAME;
EOF

git clone https://github.com/seanballais/botos ~/botos

# Assuming that the excel files have 3 sheets
pip install xlsx2csv pandas numpy
mkdir split
for f in $HOME/botos-setup-scripts/xlsx/*.xlsx
do
  for i in {1..3}
  do
    fb=${f##*/}
    xlsx2csv -s $i "$HOME/botos-setup-scripts/xlsx/$fb" "$HOME/botos-setup-scripts/xlsx/split/${fb%.*}-$i.csv"
  done
done
python $HOME/botos-setup-scripts/xlsx/split/merge-users.py
cp "$HOME/botos-setup-scripts/xlsx/split/userdata.csv" ~/botos
cp "$HOME/botos-setup-scripts/upload_users.py" ~/botos

cd ~/botos
pipenv install
pipenv install --dev numpy pandas
cp "$SCRIPT_DIR/botos.env" ~/botos/botos.env
cp "$SCRIPT_DIR/botos_dev.env" ~/botos/botos_dev.env
echo "[scripts]" >> ~/botos/Pipfile
echo "setup=\"sh $HOME/botos-setup-scripts/botos_py_setup.sh\"" >> ~/botos/Pipfile
chmod +x ~/botos-setup-scripts/botos_py_setup.sh
pipenv run setup
