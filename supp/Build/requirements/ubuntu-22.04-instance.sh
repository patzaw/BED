## User setup
echo 'startup_message off' >> ~/.screenrc

## Updates
sudo apt-get update -y
sudo apt-get dist-upgrade -y

## R
sudo apt install -y --no-install-recommends software-properties-common dirmngr
# wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d_ubuntu_key.asc
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
sudo apt-get update -y
sudo apt install -y --no-install-recommends r-base

## Add Docker
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# Add the repository to Apt sources:
echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install  -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER

## Others
sudo apt-get install -y jq pandoc build-essential libz-dev libfontconfig1-dev libssl-dev libxml2-dev libcurl4-openssl-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev gfortran

## Pandoc
wget https://github.com/quarto-dev/quarto-cli/releases/download/v1.4.553/quarto-1.4.553-linux-amd64.deb
sudo dpkg -i quarto-1.4.553-linux-amd64.deb

## Install R packages
mkdir -p ~/Documents/Development
cd ~/Documents/Development
git clone https://github.com/patzaw/BED.git
R -e "source('BED/supp/Build/requirements/R-packages.R')";
