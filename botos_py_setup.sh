#!bin/bash
pip install pandas numpy # dev dependencies to upload users
# export env vars
set -o allexport
source ~/botos/botos.env
set +o allexport

python manage.py makemigrations
python manage.py migrate

mkdir -p ~/botos/botos/static
python manage.py collectstatic

# create the superuser
echo "from django.contrib.auth import get_user_model; User=get_user_model(); User.objects.create_super_user('$BOTOS_DATABASE_USERNAME', 'electionsemail@gmail.com', '$BOTOS_DATABASE_PASSWORD')" | python manage.py shell

# gunicorn setup
sudo cp "~/botos-setup-scripts/botos-gunicorn.socket" /etc/systemd/system
sudo sed -e "s|<botos-path>|~/botos|g" -e "s|<venv-path>|$(pipenv --venv)|g" "~/botos-setup-scripts/botos-gunicorn.service" > /etc/systemd/system/botos-gunicorn.service
sudo systemctl enable --now botos-gunicorn.socket

# setup nginx
sudo mkdir -p /etc/nginx/sites-available
sudo sed -e "s|<botos-path|~/botos|g" "~/botos-setup-scripts/botos" > /etc/nginx/sites-available/botos
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/botos /etc/nginx/sites-enabled
sudo systemctl restart nginx

# Assuming that the excel files have 3 sheets
pip install xlsx2csv
mkdir split
for f in ~/botos-setup-scripts/*.xlsx
do
  for i in {1..3}
  do
    xlsx2csv -s $i $f "~/botos-setup-scripts/xlsx/split/${f%.*}-$i.csv"
  done
done
python ~/botos-setup-scripts/xlsx/split/merge-users.py
cp "~/botos-setup-scripts/xlsx/split/userdata.csv" ~/botos
cp "~/botos-setup-scripts/upload_users.py" ~/botos
echo "exec(open(upload_users.py).read())" | python manage.py shell
