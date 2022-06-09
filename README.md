# botos-setup-scripts
Scripts for setting up Botos, the election system used in PSHS-EVC
# What this script does
This scripts helps you set up a minimal installation of botos to be run on a server, whether on a VM or on actual hardware. This script is meant to be used with Debian based Linux distros / anything that runs apt.
# What this script does NOT
This script does not come with setting up the domain or setting up SSL with the site. Whether the domain or SSL will work will also depend on the server provider, however you are still free to adjust the configuration to add such features to your liking. This script also does not include a script to clean data at the moment. Because of this, you will have to validate and clean the student info yourself before running the scripts.

Note that this script has not been thoroughly tested. This is not a substitution for following the installation instructions on the Botos wiki. **READ THE BOTOS WIKI** before you run these scripts so you do not run into unnecessary issues while using the installation scripts.
# Preparation before running the script
*Note: make sure you are not in the `root` user when following these instructions. Switch or create a sudo user first*
Clone this repository to your home directory
```
git clone https://github.com/lawrencetheabhorrence/botos-setup-scripts ~/botos
```
First edit the `botos.env` file and fill it out with the relevant information. You can refer to the Botos wiki for examples. After that, you should transfer the Excel files containing the Student Information into the `xlsx` folder. Follow the guidelines in `Data_Cleaning_Guidelines.md` to avoid errors in uploading or converting student data. If the data does not follow guidelines, then clean the data first. Then execute the following commands and follow the prompts:
```
chmod +x *.sh
cd ~/botos
pipenv shell
set +o allexport
source botos.env
set -o allexport
~/botos-setup-scripts/botos_py_setup.sh
```
