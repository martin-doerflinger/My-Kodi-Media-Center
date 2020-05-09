### THIS SCRIPT ONLY WORKS ON WINDOWS 7 TO 10 IF YOUR PC IS NOT IN POWERSAVING MODE!!! ###
# Only Run with Admin privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
Add-Type -AssemblyName System.IO.Compression.FileSystem # allows unzipping files

$kodiversion="kodi-18.6-Leia"
$kodiverion_short="leia"
$programfiles = ${env:ProgramFiles}
$programfilesx86 = (${env:ProgramFiles(x86)}, ${env:ProgramFiles} -ne $null)[0]
$tmpfolder="$env:LOCALAPPDATA\Temp"
$kodipath="$env:APPDATA\Kodi"
$addonpath="$kodipath\addons"
$cdmpath="$kodipath\cdm"
$pkgpath="$addonpath\packages"
$userpath="$kodipath\userdata"
$dbpath="$userpath\Database"
$latest_ultrastar="https://github.com/ultrastares/ultrastar-worldparty/releases/download/19.12/WorldParty.19.12.installer.exe"

$kodi_repo="https://mirrors.kodi.tv/addons/$kodiverion_short/"
$kodi_addons=@("plugin.program.autocompletion","resource.images.studios.white","resource.images.weatherfanart.multi","resource.images.weathericons.white","resource.language.de_de","script.extendedinfo","script.image.resource.select","script.module.addon.signals","script.module.arrow","script.module.autocompletion","script.module.beautifulsoup","script.module.beautifulsoup4","script.module.certifi","script.module.chardet","script.module.dateutil","script.module.future","script.module.idna","script.module.inputstreamhelper","script.module.kodi-six","script.module.kodi65","script.module.mechanize","script.module.metadatautils","script.module.musicbrainz","script.module.myconnpy","script.module.pyxbmct","script.module.requests","script.module.routing","script.module.simplecache","script.module.simplejson","script.module.six","script.module.unidecode","script.module.urllib3","script.module.win_inet_pton","script.module.youtube.dl","script.skin.helper.service","script.skinshortcuts","skin.eminence.2","weather.openweathermap.extended")
$kodinerds_repo="https://github.com/kodinerds/repo/raw/master/"
$kodinerds_addons=@("repository.kodinerds","script.module.pydes","repository.castagnait")
$marcelveldt_repo="https://github.com/kodi-community-addons/repository.marcelveldt/raw/master/"
$marcelveldt_addons=@("script.module.mechanicalsoup","script.module.thetvdb","script.module.cherrypy","script.module.metadatautils","plugin.audio.spotify")
$sandmann79_repo="https://github.com/Sandmann79/xbmc/raw/master/packages/"
$sandmann79_addons=@("repository.sandmann79.plugins","script.module.mechanicalsoup","script.module.pyautogui","plugin.video.amazon-test")
$casagnait_repo="https://raw.githubusercontent.com/CastagnaIT/repository.castagnait/master/"
$casagnait_addons=@("plugin.video.netflix")
$slyguy_repo="https://k.slyguy.xyz/.repo/"
$slyguy_addons=@("repository.slyguy","script.module.slyguy","slyguy.disney.plus")
$martinjohannes93_repo="https://github.com/martin-doerflinger/kodi-plugins/raw/master/packages/"
$martinjohannes93_addons=@("repository.martinjohannes93.plugins","script.browser.chromium-launcher","script.game.emulationstation-launcher","script.game.ultrastarworldparty-launcher")
$kodi_repos=("kodi","kodinerds","marcelveldt","sandmann79","casagnait","slyguy","martinjohannes93")

### Do not change anything below here ###
function create_dir{
	param([string]$dir)
	if(!(Test-Path $dir)) {
		New-Item -ItemType Directory -Force -Path $dir | Out-Null
	}
}

function unzip($zipfile, $outdir)
{
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($zipfile)
    foreach ($entry in $archive.Entries)
    {
        $entryTargetFilePath = [System.IO.Path]::Combine($outdir, $entry.FullName)
        $entryDir = [System.IO.Path]::GetDirectoryName($entryTargetFilePath)
		create_dir $entryDir

        if(!$entryTargetFilePath.EndsWith("\")){
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $entryTargetFilePath, $true);
        }
    }
    $archive.Dispose()
}

function install_kodi{
	if ((gwmi win32_operatingsystem | select osarchitecture).osarchitecture -eq "64-bit") {
		Invoke-WebRequest -Uri (-join("http://mirrors.kodi.tv/releases/windows/win64/", $kodiversion, "-x64.exe")) -OutFile "$tmpfolder\kodi.exe"
	}
	else {
		Invoke-WebRequest -Uri (-join("http://mirrors.kodi.tv/releases/windows/win64/", $kodiversion, "-x86.exe")) -OutFile "$tmpfolder\kodi.exe"
	}
	"$tmpfolder\kodi.exe /S /v/qn"
}

function install_ultrastar{
	Invoke-WebRequest -Uri $latest_ultrastar -OutFile "$tmpfolder\WorldPartySetup.exe"
	"$tmpfolder\WorldPartySetup.exe /S /v/qn"
}

function install_emulationstation{
	Invoke-WebRequest -Uri "https://github.com/Francommit/win10_emulation_station/archive/master.zip" -OutFile "$tmpfolder\emulationstation.zip"
	unzip -zipfile "$tmpfolder\emulationstation.zip" -outdir "$tmpfolder"
	& ((Split-Path $MyInvocation.InvocationName) + "$tmpfolder\win10_emulation_station-master\prepare.ps1")
}

function install_widevine{
	if ((gwmi win32_operatingsystem | select osarchitecture).osarchitecture -eq "64-bit") {
		Invoke-WebRequest -Uri "https://redirector.gvt1.com/edgedl/widevine-cdm/4.10.1146.0-win-x64.zip" -OutFile "$cdmpath\cdm.zip"
	}
	else {
		Invoke-WebRequest -Uri "https://redirector.gvt1.com/edgedl/widevine-cdm/4.10.1146.0-win-ia32.zip" -OutFile "$cdmpath\cdm.zip"
	}
	unzip -zipfile "$cdmpath\cdm.zip" -outdir "$cdmpath"
}

function get_kodi_addon_repo{
	param([string]$url, [string]$name)
	Invoke-WebRequest -Uri $url -OutFile $name
}

function download_kodi_addon{
	param([string]$addonxml, [string]$name, [string]$repourl)
	$xml = [xml](Get-Content $addonxml)
	$addon_attributes = $xml.addons.addon | Where-Object { $_.id -eq $name }
	$latest_version = $addon_attributes.version
	Invoke-WebRequest -Uri "$repourl/$name/$name-$latest_version.zip" -OutFile "$pkgpath\$name.zip"
}

function install_kodi_addon{
	param([string]$addonxml, [string]$name, [string]$repourl)
	download_kodi_addon $addonxml $name $repourl
	unzip -zipfile "$pkgpath\$name.zip" -outdir "$addonpath"
	sqlite3 "$dbpath\Addons27.db" "UPDATE installed SET enabled = 1 WHERE addonID = '$name'"
}

function install_kodi_addons{
	foreach($repo in $kodi_repos){
		$repo_url=Get-Variable -Name $repo"_repo" -ValueOnly
		$addons=Get-Variable -Name $repo"_addons" -ValueOnly
		get_kodi_addon_repo $repo_url"/addons.xml" $tmpfolder\$repo"_addons.xml"	
		
		foreach($kodi_addon in $addons){
			install_kodi_addon $tmpfolder\$repo"_addons.xml" $kodi_addon $repo_url
		}
	}
}

function setup_kodi{
	Invoke-WebRequest -Uri "https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/files/script.skinshortcuts.zip" -OutFile "$userpath\addon_data\script.skinshortcuts.zip"
	unzip -zipfile "$userpath\addon_data\script.skinshortcuts.zip" -outdir "$userpath\addon_data"
	Invoke-WebRequest -Uri "https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/home/usr/.kodi/addons/skin.eminence.2/extras/icons/disneyplus.png" -OutFile "$addonpath\skin.eminence.2\extras\icons\disneyplus.png"
	Invoke-WebRequest -Uri "https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/home/usr/.kodi/addons/skin.eminence.2/extras/icons/prime_video.png" -OutFile "$addonpath\skin.eminence.2\extras\icons\prime_video.png"
	Invoke-WebRequest -Uri "https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/home/usr/.kodi/userdata/guisettings.xml" -OutFile "$userpath\guisettings.xml"
	Invoke-WebRequest -Uri "https://github.com/martin-doerflinger/My-Kodi-Media-Center/raw/master/home/usr/.kodi/userdata/RssFeeds.xml" -OutFile "$userpath\RssFeeds.xml"
}

#create_dir $kodipath
#create_dir $addonpath
#create_dir $cdmpath
#create_dir $pkgpath
#create_dir $userpath
#create_dir $dbpath
#install_kodi
#install_ultrastar
#install_emulationstation
#install_widevine
#install_kodi_addons
setup_kodi
Read-Host -Prompt "Press Enter to exit"