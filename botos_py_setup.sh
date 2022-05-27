#!/bin/bash
cd $HOME/botos
# export env vars
set -o allexport
source $HOME/botos/botos.env
set +o allexport
source $HOME/botos/botos_dev.env

python manage.py makemigrations
python manage.py migrate

mkdir -p $HOME/botos/botos/static
python manage.py collectstatic

# create the superuser
echo "from django.contrib.auth import get_user_model; User=get_user_model(); User.objects.create_super_user('$BOTOS_DATABASE_USERNAME', 'electionsemail@gmail.com', '$BOTOS_DATABASE_PASSWORD')" | python manage.py shell

# gunicorn setup
sudo cp "$HOME/botos-setup-scripts/botos-gunicorn.socket" /etc/systemd/system
sudo sed -e "s|<botos-path>|~/botos|g" -e "s|<venv-path>|$(pipenv --venv)|g" "$HOME/botos-setup-scripts/botos-gunicorn.service" > /etc/systemd/system/botos-gunicorn.service
sudo systemctl enable --now botos-gunicorn.socket

# setup nginx
sudo mkdir -p /etc/nginx/sites-available
sudo sed -e "s|<botos-path|~/botos|g" "$HOME/botos-setup-scripts/botos" > /etc/nginx/sites-available/botos
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/botos /etc/nginx/sites-enabled
sudo systemctl restart nginx

echo "exec(open(upload_users.py).read())" | python manage.py shell
