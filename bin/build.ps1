#
#   FILE: BUILD.PS1 
#   TYPE: PWSH_SCRIPT
#
#   This file is used by a bot (KIEDTL-MACHINE) to 
#   automatically update Open-Scoop application manifests
#   and add appropriate tags.
#
#   BUCKET MAINTAINERS: This script assumes that Scoop
#   is installed in $env:USERPROFILE\scoop and that Open-Scoop
#   is installed in $env:USERPROFILE\scoop\proj\open-scoop 
#
#   Please do not edit this file. Any pull requests
#   with this file edited WILL NOT be accepted.
#       _            _
#    __| |_ __ _ _ _| |_
#   (_-<  _/ _` | '_|  _|
#   /__/\__\__,_|_|  \__|
# 


$USER = $env:USERNAME
$APPLIST = "../APPLIST.md"
$SCOOP = scoop which scoop
if ( !$env:SCOOP_HOME ) { 
  $env:SCOOP_HOME = resolve-path (split-path (split-path (scoop which scoop))) 
}
$checkver = "C:\\Users\\$USER\\scoop\\apps\\scoop\\current\\bin\\checkver.ps1"
$dir = "C:\\Users\\$USER\\scoop\\proj\\open-scoop" 

Set-Location $HOME
Set-Location scoop/proj/open-scoop/bin

git pull > log.txt

$files = Get-ChildItem ../.\*.json
$i = 1;
Get-ChildItem ../.\*.json | Foreach-Object {
  $basename = $_.BaseName
  Write-Progress -Activity "Updating application manifests" -status "Scanning $basename.json" -percentComplete ($i / $files.count * 100)
  $out = ../../../apps/scoop/current/bin/checkver.ps1 -dir $dir -App $basename -u | Out-String
  git commit -q -a -m "Auto-updated $basename" > log.txt
  $i++
}

Set-Content -Path "../APPLIST.md" -Value "# List of apps`n---`nAutomatically generated by the bin/build.ps1 script`r`n" -NoNewline

Add-Content -Path "../APPLIST.md" -Value "| Name | Version |`n" -NoNewline
Add-Content -Path "../APPLIST.md" -Value "| ---- | ------- |`n" -NoNewline

Get-ChildItem ../.\*.json | Foreach-Object {
	$appname = $_.BaseName
	$appdata = Get-Content $_ | ConvertFrom-JSON
	$version = $appdata.version
	Add-Content -Path "../APPLIST.md" -Value "| $appname | $version |`r`n" -NoNewline
}

Add-Content -Path "../APPLIST.md" -Value "`r`nThis file was automatically generated." -NoNewline


# Commit and tagging

Set-Location ..

$smajor = Get-Content versdat/major.txt
$sminor = Get-Content versdat/minor.txt
$sbuild = Get-Content versdat/build.txt
$major = [int]$smajor
$minor = [int]$sminor
$build = [int]$sbuild

if ($build -gt 255 -and $minor -lt 255) {
	$minor++
	$build = 0
}
elseif ($build -gt 255 -and $minor -gt 255) {
	$build = 0
	$minor = 0
	$major++
}
else {
	$build++
}

$smajor = [string]$major
$sminor = [string]$minor
$sbuild = [string]$build

Set-Content -Path versdat/major.txt -Value $smajor
Set-Content -Path versdat/minor.txt -Value $sminor
Set-Content -Path versdat/build.txt -Value $sbuild

Write-Output "Finished updating app manifests"
Write-Output "Creating GitHub release ${smajor}.${sminor}.${sbuild}"

$version = "${smajor}.${sminor}.${sbuild}"
$latestcommit = git rev-parse HEAD

git tag -a -m "Automatically_added_tag_$version" "v$version" $latestcommit 

Write-Output "`a"
Remove-Item log.txt