#!/bin/bash

for i in "$@"; do
  case $i in
    --user=*) user="${i#*=}"; shift;;
  esac;
done;

# only run as run, will ask for password
# however, it will use the current user as argument (kodi will be installed for that user)
# If you want to install kodi for another user, run `sudo setup.sh --user=<user>`
if [[ "$EUID" -ne 0 ]]; then
  user=`whoami`
  exec sudo -- "$0" "$@" "--user=$user"
fi

# set variables
kodi_verion="leia"
dist=`lsb_release -sc`
ARCH="${ARCH:-$(uname -m)}"
tmppath="/tmp"
autostart="/home/$user/.config/autostart"
kodipath="/home/$user/.kodi"
addonpath="$kodipath/addons"
cdmpath="$kodipath/cdm"
pkgpath="$addonpath/packages"
userpath="$kodipath/userdata"
dbpath="$userpath/Database"
keymap_path="/etc/rc_keymaps"
keymap="talon_media_remote" # you can change this to talon_media_remote, xbox_one, khadas_small
LANG="DE"

# apt packages
declare -a apt_packages=("at" "automake" "build-essential" "bzip2" "chromium-browser" "cmake" "dialog" "dvb-apps" "ffmpeg" "fpc" "gcc" "git" "gufw" "ir-keytable" "kodi" "kodi-eventclients-kodi-send" "kodi-inputstream-adaptive" "kodi-inputstream-rtmp" "kodi-pvr-hts" "kodi-pvr-iptvsimple" "kodi-pvr-tvheadend-hts" "kodi-pvr-vuplus" "language-pack-de" "language-pack-gnome-de" "language-selector-gnome" "libasound2-dev" "libavahi-client-dev" "libavcodec-dev" "libavformat-dev" "libavresample-dev" "libavutil-dev" "libboost-date-time-dev" "libboost-filesystem-dev" "libboost-locale-dev" "libboost-system-dev" "libcurl4-openssl-dev" "libdvbcsa-dev" "libeigen3-dev" "libfreeimage-dev" "libfreetype6-dev" "libgl1-mesa-dev" "libkodiplatform17" "liblua5.3-dev" "libopencv-highgui-dev" "libportmidi-dev" "libproc-processtable-perl" "libsdl2-dev" "libsdl2-image-dev" "libsqlite3-dev" "libssl-dev" "libswscale-dev" "liburiparser-dev" "libvulkan1" "libxml++" "libxml++-dev" "make" "mesa-vulkan-drivers" "net-tools" "openssh-server" "pkg-config" "portaudio19-dev" "python-pip" "python-requests" "samba" "samba-common" "software-properties-common" "sqlite3" "ufw" "unattended-upgrades" "unzip" "vorbis-tools" "vulkan-utils" "wget" "xmlstarlet" "zlib1g-dev")

# retropie optional packages
declare -a retropie_opt=("advmame-0.94" "advmame-1.4" "advmame" "ags" "atari800" "basilisk" "dgen" "dosbox" "fbzx" "frotz" "fuse" "hatari" "jzintv" "linapple" "openmsx" "osmose" "ppsspp" "reicast" "scummvm" "simcoupe" "stella" "stratagus" "vice" "xroar" "zesarux" "lr-beetle-lynx" "lr-beetle-psx" "lr-beetle-vb" "lr-beetle-wswan" "lr-bluemsx" "lr-bsnes" "lr-fbalpha2012" "lr-fmsx" "lr-freeintv" "lr-gw" "lr-mame2010" "lr-mrboom" "lr-nxengine" "lr-o2em" "lr-parallel-n64" "lr-ppsspp" "lr-prboom" "lr-snes9x" "lr-tgbdual" "lr-tyrquake" "alephone" "cannonball" "darkplaces-quake" "dxx-rebirth" "eduke32" "lincity-ng" "love-0.10.2" "love" "micropolis" "openpht" "openttd" "opentyrian" "sdlpop" "smw" "solarus" "supertux" "tyrquake" "uqm" "wolf4sdl" "xrick" "zdoom" "scraper" "usbromservice")

# retropie driver packages
declare -a retropie_driver=("custombluez" "customhidsony" "ps3controller" "sixaxis" "snesdev" "steamcontroller" "xarcade2jstick" "xboxdrv" "xpad")

# experimental packages
declare -a retropie_exp=("dolphin" "dosbox-sdl2" "fs-uae" "minivmac" "oricutron" "pcsx2" "px68k" "quasi88" "residualvm" "sdltrs" "ti99sim" "xm7" "lr-4do" "lr-81" "lr-beetle-pcfx" "lr-beetle-saturn" "lr-desmume2015" "lr-desmume" "lr-dinothawr" "lr-dolphin" "lr-dosbox" "lr-flycast" "lr-freechaf" "lr-hatari" "lr-kronos" "lr-mame2003-plus" "lr-mame2015" "lr-mame2016" "lr-mame" "lr-mess2016" "lr-mess" "lr-muppen64plux-next" "lr-np2kai" "lr-pokemini" "lr-puae" "lr-px68k" "lr-quasi88" "lr-redream" "lr-scummvm" "lr-superflappybirds" "lr-vice" "lr-virtualjaguar" "lr-x1" "lr-yabause" "abuse" "bombermaaan" "cdogs-sdl" "cgenius" "digger" "gemrb" "ioquake3" "jumpnbump" "mysticmine" "openblok" "splitwolf" "srb2" "yquake2" "attractmode" "emulationstation-dev" "launchingimages" "mehstation" "mobilegamepad" "pegasus-fe" "retropie-manager" "skyscraper" "virtualgamepad")

# kodi repos + addons
kodi_repo="https://mirrors.kodi.tv/addons/$kodi_verion/"
declare -a kodi_addons=("plugin.program.autocompletion" "resource.images.studios.white" "resource.images.weatherfanart.multi" "resource.images.weathericons.white" "resource.language.de_de" "script.extendedinfo" "script.image.resource.select" "script.module.addon.signals" "script.module.arrow" "script.module.autocompletion" "script.module.beautifulsoup" "script.module.beautifulsoup4" "script.module.certifi" "script.module.chardet" "script.module.dateutil" "script.module.future" "script.module.idna" "script.module.inputstreamhelper" "script.module.kodi-six" "script.module.kodi65" "script.module.mechanize" "script.module.metadatautils" "script.module.musicbrainz" "script.module.myconnpy" "script.module.pyxbmct" "script.module.requests" "script.module.routing" "script.module.simplecache" "script.module.simplejson" "script.module.six" "script.module.unidecode" "script.module.urllib3" "script.module.youtube.dl" "script.skin.helper.service" "script.skinshortcuts" "skin.eminence.2" "weather.openweathermap.extended")

kodinerds_repo="https://github.com/kodinerds/repo/raw/master/"
declare -a kodinerds_addons=("repository.kodinerds" "script.module.pydes" "repository.castagnait")

marcelveldt_repo="https://github.com/kodi-community-addons/repository.marcelveldt/raw/master/"
declare -a marcelveldt_addons=("script.module.mechanicalsoup" "script.module.thetvdb" "script.module.cherrypy" "script.module.metadatautils" "plugin.audio.spotify")

sandmann79_repo="https://github.com/Sandmann79/xbmc/raw/master/packages/"
declare -a sandmann79_addons=("repository.sandmann79.plugins" "script.module.mechanicalsoup" "script.module.pyautogui" "plugin.video.amazon-test")

casagnait_repo="https://raw.githubusercontent.com/CastagnaIT/repository.castagnait/master/"
declare -a casagnait_addons=("plugin.video.netflix")

slyguy_repo="https://k.slyguy.xyz/.repo/"
declare -a slyguy_addons=("repository.slyguy" "script.module.slyguy" "slyguy.disney.plus")

martinjohannes93_repo="https://github.com/martin-doerflinger/kodi-plugins/raw/master/packages/"
declare -a martinjohannes93_addons=("repository.martinjohannes93.plugins" "script.browser.chromium-launcher" "script.game.emulationstation-launcher" "script.game.ultrastarworldparty-launcher")

# declare repos which you want to install
declare -a kodi_repos=("kodi" "kodinerds" "marcelveldt" "sandmann79" "casagnait" "slyguy" "martinjohannes93")

### DO NOT EDIT ANYTHING BELOW HERE ###

# Supress Output if possible
export PIP_DISABLE_PIP_VERSION_CHECK=1
export PYTHONWARNINGS="ignore:DEPRECATION"
export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical

update_apt_repository()
{
  apt-get update --fix-missing -y
  apt-get upgrade -y -q -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold"
  apt-get dist-upgrade -y -q -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold"
}

update_pip_repository()
{
  pip install --upgrade pip
}

add_apt_repository()
{
  add-apt-repository -y $1
}

install_apt_package()
{
  apt-get install -y -q $1
}

install_pip_package()
{
  sudo -u $user bash -c "pip install --user $1"
}

create_dir()
{
  if [ ! -d $1 ]; then
    mkdir -p $1
  fi
}

create_dir_user()
{
  if [ ! -d $1 ]; then
    sudo -u $user bash -c "mkdir -p $1"
  fi
}

get_latest_commit()
{
  LATEST_URL="$(curl -Ls -o /dev/null -w %{url_effective} "${1}")"
  COMMIT_STRING="$(wget -q "$LATEST_URL" -O - | grep -Po -m 1 'commit\/([a-z0-9]*)')"
  echo ${COMMIT_STRING//commit\//}
}

get_kodi_addon_repo()
{
  URL="$(curl -Ls -o /dev/null -w %{url_effective} "${2}")"
  wget -qN --show-progress $URL -O $tmppath/$1
  echo $1
}

download_kodi_addon()
{
  latest_version=$(cat $tmppath/$1 | tr '\n' ' ' | grep -Po -m 1 "id=\"$2\".*" | grep -Po -m 1 "version=\"([0-9.]*)\"" | grep -Po -m 1 "([0-9.]*)")
  FILE_URL="$3/$2/$2-$latest_version.zip"
  URL="$(curl -Ls -o /dev/null -w %{url_effective} "${FILE_URL}")"
  wget -qN --show-progress $URL -O $pkgpath/$2.zip
}

install_ultrastar()
{
  if [ ! -d "$tmppath/usdxworldparty" ];
    then sudo -u $user bash -c "git clone https://github.com/ultrastares/usdxworldparty.git $tmppath/usdxworldparty" ; cd $tmppath/usdxworldparty ;
    else cd $tmppath/usdxworldparty ; sudo -u $user bash -c "git pull" ;
  fi

  LATEST_COMMIT=$(get_latest_commit "https://github.com/ultrastares/ultrastar-worldparty/releases/latest")
  sudo -u $user bash -c "git reset --hard $LATEST_COMMIT"
  sudo -u $user bash -c "./autogen.sh"
  sudo -u $user bash -c "./configure"
  sudo -u $user bash -c "make"
  make install
}

install_performous_tools()
{
  if [ ! -d "$tmppath/performous-tools" ];
    then sudo -u $user bash -c "git clone https://github.com/performous/performous-tools.git $tmppath/performous-tools" ; cd $tmppath/performous-tools ;
    else cd $tmppath/performous-tools ; sudo -u $user bash -c "git pull" ;
  fi

  sudo -u $user bash -c "mkdir build"
  cd build
  sudo -u $user bash -c "cmake .."
  sudo -u $user bash -c "make"
  make install

  if [ ! -d "$tmppath/composer" ];
    then sudo -u $user bash -c "git clone https://github.com/performous/composer.git $tmppath/composer" ; cd $tmppath/composer ;
    else cd $tmppath/composer ; sudo -u $user bash -c "git pull" ;
  fi

  sudo -u $user bash -c "mkdir build"
  cd build
  sudo -u $user bash -c "cmake .."
  sudo -u $user bash -c "make"
  make install
}

install_retropie_packages()
{
for var in "${$1[@]}"
  do
    ./retropie_packages.sh $var depends
    ./retropie_packages.sh $var sources
    ./retropie_packages.sh $var build
    ./retropie_packages.sh $var install
    ./retropie_packages.sh $var configure
  done
}

install_retropie()
{
  if [ ! -d "$tmppath/RetroPie-Setup" ];
    then sudo -u $user bash -c "git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git $tmppath/RetroPie-Setup"; cd $tmppath/RetroPie-Setup ;
    else cd $tmppath/RetroPie-Setup ; sudo -u $user bash -c "git pull" ;
  fi

  scriptdir="$tmppath/RetroPie-Setup"
  "$scriptdir/retropie_packages.sh" setup basic_install
  "$scriptdir/retropie_packages.sh" setup update_packages

  install_retropie_packages $retropie_opt
  install_retropie_packages $retropie_driver
  install_retropie_packages $retropie_exp
}

install_tvheadend()
{
  if [ ! -d "$tmppath/tvheadend" ];
    then sudo -u $user bash -c "git clone --depth=1 https://github.com/tvheadend/tvheadend.git $tmppath/tvheadend"; cd $tmppath/tvheadend ;
    else cd $tmppath/tvheadend ; sudo -u $user bash -c "git pull" ;
  fi
  ./Autobuild.sh
  make install
}

install_widevine()
{
  case "$ARCH" in
    x86_64) sudo -u $user bash -c "wget -qN --show-progress https://redirector.gvt1.com/edgedl/widevine-cdm/4.10.1440.19-linux-ia32.zip -O $cdmpath/cdm.zip" ;;
    i?86) sudo -u $user bash -c "wget -qN --show-progress https://redirector.gvt1.com/edgedl/widevine-cdm/4.10.1440.19-linux-x64.zip -O $cdmpath/cdm.zip" ;;
    arm*) sudo -u $user bash -c "wget -qN --show-progress https://blog.vpetkov.net/wp-content/uploads/2019/08/libwidevinecdm.so_.zip -O $cdmpath/cdm.zip" ;;
    *) echo "The architecture $ARCH is not supported." >&2 ; exit 1 ;;
  esac

  sudo -u $user bash -c "unzip -u $cdmpath/cdm.zip -d $cdmpath"
}

kodi_update_local_addons()
{
  sleep 3
  sudo -u $user bash -c 'kodi-send -a "UpdateLocalAddons()"'
  sleep 3
}

install_kodi_addon()
{
  download_kodi_addon "$1" "$2" "$3"
  sudo -u $user bash -c "unzip -u $pkgpath/$2.zip -d $addonpath"
  kodi_update_local_addons
  sudo -u $user bash -c "sqlite3 $dbpath/Addons27.db 'UPDATE installed SET enabled = 1 WHERE addonID = \"$2\"'"
}

setup_kodi()
{
  chown -R $user:$user $kodipath
  sudo -u $user bash -c "kodi &"
  sleep 2
  pids=$(pgrep kodi)
  kill -9 $pids
  kodi_update_local_addons
}

setup_ubuntu()
{
  if [[ "$LANG" -eq "DE" ]]; then
    locale-gen de_DE.UTF-8
    sed -i 's/LANG=.*/LANG=de_DE.UTF-8/g' /etc/default/locale
    sed -i 's/XKBMODEL=.*/XKBMODEL=pc105/g' /etc/default/keyboard
    sed -i 's/XKBLAYOUT=.*/XKBLAYOUT=de/g' /etc/default/keyboard
    sed -i 's/XKBVARIANT=.*/XKBVARIANT=basic/g' /etc/default/keyboard
    setxkbmap -model pc105 -layout de -variant basic
    gsettings reset org.gnome.desktop.input-sources xkb-options
  fi

  rm -rf /home/$user/Public
  rm -rf /home/$user/Templates
  rm -rf /home/$user/Öffentlich
  rm -rf /home/$user/Vorlagen
  sudo -u $user bash -c "mkdir /home/$user/Songs"
  sudo -u $user bash -c "mkdir /home/$user/Recordings"
  sudo -u $user bash -c "ln -s /home/$user/Songs/ /home/$user/.WorldParty/songs"

  sudo -u $user bash -c 'dconf write /org/compiz/profiles/unity/plugins/unityshell/launcher-capture-mouse false'
  sudo -u $user bash -c 'dconf write /org/compiz/profiles/unity/plugins/unityshell/icon-size 35'
  sudo -u $user bash -c 'gsettings set org.gnome.desktop.screensaver lock-enabled false'
  sudo -u $user bash -c 'gsettings set org.gnome.desktop.lockdown disable-lock-screen true'
  sudo -u $user bash -c 'gsettings set org.gnome.desktop.background picture-uri file:///usr/share/backgrounds/Manhattan_Sunset_by_Giacomo_Ferroni.jpg'
  sudo -u $user bash -c 'gsettings set org.gnome.desktop.interface clock-show-date true'
  sudo -u $user bash -c 'gsettings set org.gnome.desktop.session idle-delay 0'
  sudo -u $user bash -c 'gsettings set org.gnome.desktop.media-handling automount-open false'
  sed -i 's/enabled=1/enabled=0/g' /etc/default/apport # suppress warnings/errors - note: not recommended on most systems, but anoying when watching movies, etc.

  sudo -u $user bash -c "wget -qN --show-progress https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/.config/autostart/kodi.desktop -O $autostart/kodi.desktop"
  update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/chromium-browser 200

  sed -i 's/\/\/\t"${distro_id}:${distro_codename}-updates";/\t"${distro_id}:${distro_codename}-updates";/g' /etc/apt/apt.conf.d/50unattended-upgrades
  sed -i 's/\/\/Unattended-Upgrade::Remove-Unused-Kernel-Packages "false";/Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";/g' /etc/apt/apt.conf.d/50unattended-upgrades
  sed -i 's/\/\/Unattended-Upgrade::Remove-Unused-Dependencies "false";/Unattended-Upgrade::Remove-Unused-Dependencies "true";/g' /etc/apt/apt.conf.d/50unattended-upgrades
  wget -qN --show-progress https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/etc/apt/apt.conf.d/20auto-upgrades -O /etc/apt/apt.conf.d/20auto-upgrades

  ufw enable
  ufw default deny incoming
  ufw default allow outgoing

  sudo -u $user bash -c "wget -qN --show-progress https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/home/usr/.emulationstation/es_input.cfg -O /home/$user/.emulationstation/es_input.cfg"

  sudo -u $user bash -c "wget -qN --show-progress https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/files/script.skinshortcuts.zip -O $userpath/addon_data/script.skinshortcuts.zip"
  sudo -u $user bash -c "unzip -u $userpath/addon_data/script.skinshortcuts.zip -d $userpath/addon_data/"
  sudo -u $user bash -c "wget -qN --show-progress https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/home/usr/.kodi/addons/skin.eminence.2/extras/icons/disneyplus.png -O $addonpath/skin.eminence.2/extras/icons/disneyplus.png"
  sudo -u $user bash -c "wget -qN --show-progress https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/home/usr/.kodi/addons/skin.eminence.2/extras/icons/prime_video.png -O $addonpath/skin.eminence.2/extras/icons/prime_video.png"
  sudo -u $user bash -c "wget -qN --show-progress https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/home/usr/.kodi/userdata/guisettings.xml -O $userpath/guisettings.xml"
  sudo -u $user bash -c "wget -qN --show-progress https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/home/usr/.kodi/userdata/RssFeeds.xml -O $userpath/RssFeeds.xml"
}

setup_tvheadend()
{
  wget -qN --show-progress https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/etc/init.d/tvheadend -O /etc/init.d/tvheadend
  wget -qN --show-progress https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/etc/systemd/system/tvheadend.service -O /etc/systemd/system/tvheadend.service
  chmod +x /etc/init.d/tvheadend
  chmod +x /etc/systemd/system/tvheadend.service
  systemctl daemon-reload
  systemctl enable tvheadend
  ufw allow 9981:9982/tcp
}

setup_samba()
{
  wget -qN --show-progress https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/etc/samba/smb.conf -O /etc/samba/smb.conf
  sed -i "s/__USR__/$user/g" /etc/samba/smb.conf
  read -p "Do you want to activate Samba? (y/n)" -n 1 -r
  echo 
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    ufw allow samba
    systemctl enable smbd.service
    systemctl restart smbd.service
  fi
}

setup_ssh()
{
  read -p "Do you want to activate ssh? (y/n)" -n 1 -r
  echo 
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    ufw allow ssh
    systemctl enable ssh.service
    systemctl restart ssh.service
  fi
}

reboot()
{
  read -p "Installation finished. You should restart your PC now. This may take some time. Do you want to restart now? (y/n)" -n 1 -r
  echo 
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    /sbin/reboot
  fi
}

install_kodi_addons()
{
  for repo in "${kodi_repos[@]}"
  do
    declare -n repo_url=$"$repo""_repo"
    declare -n addons=$"$repo""_addons"
    addons_xml=$(get_kodi_addon_repo "$repo"+"_addons.xml" "$repo_url""addons_xml")

    for kodi_addon in "${addons[@]}"
    do
      install_kodi_addon $addons_xml $kodi_addon $repo_url
    done
  done
}

add_apt_repository ppa:team-xbmc/ppa
add_apt_repository universe

for apt_package in "${apt_packages[@]}"
do
  install_apt_package $apt_package
done

update_pip_repository
install_pip_package pycryptodomex
create_dir_user $kodipath
create_dir_user $cdmpath
create_dir_user $addonpath
create_dir_user $pkgpath
create_dir_user $autostart
create_dir $keymap_path
install_ultrastar
install_performous_tools
install_retropie
install_tvheadend
install_widevine
setup_kodi
install_kodi_addons
kodi_update_local_addons
setup_ubuntu
setup_tvheadend
setup_samba
setup_ssh

reboot
