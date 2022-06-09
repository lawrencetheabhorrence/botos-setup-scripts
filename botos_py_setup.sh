#!/bin/bash
cd $HOME/botos

python $HOME/botos-setup-scripts/xlsx/split/merge-users.py
cp "$HOME/botos-setup-scripts/xlsx/split/userdata.csv" ~/botos
cp "$HOME/botos-setup-scripts/upload_users.py" ~/botos

python manage.py makemigrations
python manage.py migrate

mkdir -p $HOME/botos/botos/static
python manage.py collectstatic

# create the superuser
echo "from django.contrib.auth import get_user_model; User=get_user_model(); User.objects.create_superuser('$BOTOS_DATABASE_USERNAME', '$BOTOS_EMAIL', '$BOTOS_DATABASE_PASSWORD')" | python manage.py shell

# gunicorn setup
sudo cp "$HOME/botos-setup-scripts/botos-gunicorn.socket" /etc/systemd/system
cp "$HOME/botos-setup-scripts/botos-gunicorn.service" /etc/systemd/system/botos-gunicorn.service
sudo sed -i -e "s|<botos-path>|$HOME/botos|g" -e "s|<venv-path>|$(pipenv --venv)|g" /etc/systemd/system/botos-gunicorn.service
sudo systemctl enable --now botos-gunicorn.socket

# setup nginx
sudo mkdir -p /etc/nginx/sites-available
cp "$HOME/botos-setup-scripts/botos" /etc/nginx/sites-available
sudo sed -i -e "s|<botos-path>|$HOME/botos|g" /etc/nginx/sites-available/botos
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/botos /etc/nginx/sites-enabled
sudo systemctl restart nginx

echo "exec(open(upload_users.py).read())" | python manage.py shell
