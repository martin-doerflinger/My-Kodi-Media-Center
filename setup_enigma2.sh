#!/bin/bash

kodi_verion=leia
kodipath="/usr/share/kodi"
addonpath="$kodipath/addons"
cdmpath="$kodipath/cdm"
pkgpath="$addonpath/packages"
userpath="$kodipath/userdata"
dbpath="$userpath/Database"

# kodi repos + addons
kodi_repo="https://mirrors.kodi.tv/addons/$kodi_verion"
declare -a kodi_addons=("plugin.program.autocompletion" "resource.images.studios.white" "resource.images.weatherfanart.multi" "resource.images.weathericons.white" "resource.language.de_de" "script.extendedinfo" "script.image.resource.select" "script.module.addon.signals" "script.module.arrow" "script.module.autocompletion" "script.module.beautifulsoup" "script.module.beautifulsoup4" "script.module.certifi" "script.module.chardet" "script.module.dateutil" "script.module.future" "script.module.idna" "script.module.inputstreamhelper" "script.module.kodi-six" "script.module.kodi65" "script.module.mechanize" "script.module.metadatautils" "script.module.musicbrainz" "script.module.myconnpy" "script.module.pyxbmct" "script.module.requests" "script.module.routing" "script.module.simplecache" "script.module.simplejson" "script.module.six" "script.module.unidecode" "script.module.urllib3" "script.module.youtube.dl" "script.skin.helper.service" "script.skinshortcuts" "skin.eminence.2" "weather.openweathermap.extended")

kodinerds_repo="https://github.com/kodinerds/repo/raw/master"
declare -a kodinerds_addons=("repository.kodinerds" "script.module.pydes" "repository.castagnait")

marcelveldt_repo="https://github.com/kodi-community-addons/repository.marcelveldt/raw/master"
declare -a marcelveldt_addons=("script.module.mechanicalsoup" "script.module.thetvdb" "script.module.cherrypy" "script.module.metadatautils" "plugin.audio.spotify")

sandmann79_repo="https://github.com/Sandmann79/xbmc/raw/master/packages"
declare -a sandmann79_addons=("repository.sandmann79.plugins" "script.module.mechanicalsoup" "script.module.pyautogui" "plugin.video.amazon-test")

casagnait_repo="https://raw.githubusercontent.com/CastagnaIT/repository.castagnait/master"
declare -a casagnait_addons=("plugin.video.netflix")

slyguy_repo="https://k.slyguy.xyz/.repo"
declare -a slyguy_addons=("repository.slyguy" "script.module.slyguy" "slyguy.disney.plus")

martinjohannes93_repo="https://github.com/martin-doerflinger/kodi-plugins/raw/master/packages"
declare -a martinjohannes93_addons=("repository.martinjohannes93.plugins")

# declare repos which you want to install
declare -a kodi_repos=("kodi" "kodinerds" "marcelveldt" "sandmann79" "casagnait" "slyguy" "martinjohannes93")

### do not change anything below here ###
create_dir()
{
  mkdir -p $1
}

get_kodi_addon_repo()
{
  wget $2 -O $userpath/$1
  echo $1
}

download_kodi_addon()
{
  latest_version=$(cat $userpath/$1 | tr '\n' ' ' | grep -Eo -m 1 "id=\"$2\".*" | grep -Eo -m 1 "version=\"([0-9.]*)\"" | grep -Eo -m 1 "([0-9.]*)")
  FILE_URL="$3/$2/$2-$latest_version.zip"
  wget $FILE_URL -O $pkgpath/$2.zip
}

install_kodi_addon()
{
  download_kodi_addon "$1" "$2" "$3"
  unzip -o $pkgpath/$2.zip -d $addonpath
  sqlite3 $dbpath/Addons27.db 'UPDATE installed SET enabled = 1 WHERE addonID = \"$2\"'
}

install_kodi_addons()
{
  for repo in "${kodi_repos[@]}"
  do
    declare -n repo_url=$"$repo""_repo"
    declare -n addons=$"$repo""_addons"
    addons_xml=$(get_kodi_addon_repo "$repo""_addons.xml" "$repo_url""/addons.xml")

    for kodi_addon in "${addons[@]}"
    do
      install_kodi_addon $addons_xml $kodi_addon $repo_url
    done
  done
}

setup_kodi()
{
  wget https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/files/script.skinshortcuts.zip -O $userpath/addon_data/script.skinshortcuts.zip
  unzip -o $userpath/addon_data/script.skinshortcuts.zip -d $userpath/addon_data/
  wget https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/home/usr/.kodi/addons/skin.eminence.2/extras/icons/disneyplus.png -O $addonpath/skin.eminence.2/extras/icons/disneyplus.png
  wget https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/home/usr/.kodi/addons/skin.eminence.2/extras/icons/prime_video.png -O $addonpath/skin.eminence.2/extras/icons/prime_video.png
  wget https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/home/usr/.kodi/userdata/guisettings.xml -O $userpath/guisettings.xml
  wget https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/home/usr/.kodi/userdata/RssFeeds.xml -O $userpath/RssFeeds.xml
  chown -R root:root $kodipath
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
 
create_dir $kodipath
create_dir $cdmpath
create_dir $addonpath
create_dir $pkgpath
install_kodi_addons
setup_kodi
reboot
