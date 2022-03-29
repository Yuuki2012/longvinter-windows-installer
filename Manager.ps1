#Requires -RunAsAdministrator

<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.196
	 Created on:   	2022/03/25 05:55:13 PM
	 Created by:   	Yuuki2012
	 Organization: 	Raiza.dev
	 Filename:     	Manager.ps1
	===========================================================================
	.DESCRIPTION
		Manager for Longvinter Windows Server.
#>

$global:check = 0

function success ($msg)
{
	Write-Host "[" -NoNewline
	Write-Host "✓" -NoNewline -ForegroundColor Green
	Write-Host "]" -NoNewline
	Write-Host " $msg"
}
function error ($msg)
{
	Write-Host "[" -NoNewline
	Write-Host "X" -NoNewline -ForegroundColor Red
	Write-Host "]" -NoNewline
	Write-Host " $msg"
}
function check_git-lfs
{
	Try
	{
		git-lfs | Out-Null
		success "Git-LFS is installed."
		$global:check += 1
	}
	Catch [System.Management.Automation.CommandNotFoundException]
	{
		error "Git-LFS is not installed."
	}
}
function check_software ($app)
{
	$installed32 = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -eq $app }) -ne $null
	$installed64 = (Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -eq $app }) -ne $null
	
	if ($installed32 -or $installed64)
	{
		success "$app is installed."
		$global:check += 1
	}
	else
	{
		error "$app is not intsalled."
	}
}
function check_ram ($in)
{
	$total = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1gb

	if ($total -gt $in)
	{
		success "$total GB RAM detected."
		$global:check += 1
	}
	else
	{
		error "$in GB RAM detected. You need at least 3 GB."
	}
}
function check_arch
{
	$arch = (Get-CimInstance CIM_OperatingSystem).OSArchitecture
	
	if ($arch -eq "64-bit")
	{
		success "$arch OS detected."
		$global:check += 1
	}
	else
	{
		error "$arch OS detected. You need a 64-bit system to install Longvinter Server."
	}
}
function check_os
{
	$win10 = "Microsoft Windows 10"
	$win11 = "Microsoft Windows 11"
	$os = [string](Get-CimInstance Win32_OperatingSystem).Name
	
	if ($os.Contains($win11))
	{
		success "$win11 detected."
		$global:check += 1
	}
	elseif ($os.Contains($win10))
	{
		success "$win10 detected."
		$global:check += 1
	}
	else
	{
		error "Operating System is not supported."
	}
}
function getkey
{
	$exists = Test-Path -Path ".\longvinter-windows-server\Longvinter\Saved\Logs\Longvinter.log" -PathType Leaf
	
	IF ($exists)
	{
		Write-Host ([uint64](Select-String -Pattern "0[xX][0-9a-fA-F]{15}" -Path ".\longvinter-windows-server\Longvinter\Saved\Logs\Longvinter.log").Matches.groups[0].value) -NoNewline -ForegroundColor Green
	}
	else
	{
		error "Longvinter.log not found. Please run the server first."
	}
	
	Exit
}
function update
{
	if (Test-Path ".\longvinter-windows-server\" -PathType Any)
	{
		Set-Location ".\longvinter-windows-server\"
		git fetch
		git restore .
		git pull
		Set-Location "..\"
		success "Successfully updated server."
	}
	else
	{
		error "Longvinter Windows Server is not installed."
	}
}
function backup
{
	$ctime = Get-Date -Format "yyyyMMdd-HHmm"
	mkdir ".\longvinter-windows-server\Longvinter\Backup" -ErrorAction SilentlyContinue
	tar --exclude="*Logs*" --exclude="*CrashReportClient*" -cvzf ".\longvinter-windows-server\Longvinter\Backup\$ctime.tar.gz" ".\longvinter-windows-server\Longvinter\Saved" 2> $null
	success "Created backup in .\longvinter-windows-server\Longvinter\Backup\$ctime.tar.gz"
}
function uninstall
{
	Remove-Item ".\longvinter-windows-server" -Recurse -Force -ErrorAction SilentlyContinue
	success "Removed longvinter-windows-server."
	
	$udp = Get-NetFirewallRule -DisplayName "LongvinterServer UDP" 2> $null
	$tcp = Get-NetFirewallRule -DisplayName "LongvinterServer TCP" 2> $null
	if ($udp -or $tcp)
	{
		Remove-NetFirewallRule -DisplayName "LongvinterServer UDP"
		Remove-NetFirewallRule -DisplayName "LongvinterServer TCP"
		success "Removed Firewall rules."
	}
	else
	{
		success "No firewall rules exist."
	}
	
	Remove-Item ".\Longvinter.lnk" -ErrorAction SilentlyContinue
	success "Removed Longvinter shortcut."
}

# Handle commandline arguments
if ($args.Count -eq 1)
{
	if ($args[0].ToString().ToLower() -eq "getkey")
	{
		getkey
	}
	elseif ($args[0].ToString().ToLower() -eq "update")
	{
		update
	}
	elseif ($args[0].ToString().ToLower() -eq "backup")
	{
		backup
	}
	elseif ($args[0].ToString().ToLower() -eq "uninstall")
	{
		Write-Host "Uninstalling the server will delete everything in this folder, including backups."
		$answer = Read-Host "> Are you sure you want to uninstall the server? y/n"
		
		if ($answer.ToLower() -eq "yes" -or $answer.ToLower() -eq "y")
		{
			uninstall
		}
	}
	
	Exit
}

Write-Host "Please wait while everything is being checked..."
check_software("Steam")  # argument is program name.
check_software("Git")
check_git-lfs
check_ram(3)  # argument is amount of (required) RAM in GB.
check_arch
check_os

if ($check -eq 6)
{
	Write-Host "Cloning Longvinter Windows Server repository..."
	git clone -q https://github.com/Uuvana-Studios/longvinter-windows-server.git
	
	# Fail-safe for Game.ini.default
	if (Test-Path ".\longvinter-windows-server\Longvinter\Saved\Config\WindowsServer\Game.ini.default" -PathType Leaf)
	{
		Copy-Item ".\longvinter-windows-server\Longvinter\Saved\Config\WindowsServer\Game.ini.default" ".\longvinter-windows-server\Longvinter\Saved\Config\WindowsServer\Game.ini"
	}
	else
	{
		Set-Content -Path ".\longvinter-windows-server\Longvinter\Saved\Config\WindowsServer\Game.ini" -Value "[/game/blueprints/server/gi_advancedsessions.gi_advancedsessions_c]
ServerName=Unnamed Island
MaxPlayers=32
ServerMOTD=Welcome to Longvinter Island!
Password=
CommunityWebsite=www.longvinter.com

[/game/blueprints/server/gm_longvinter.gm_longvinter_c]
AdminSteamID=97615967659669198
PVP=true
TentDecay=true
MaxTents=2"
	}
	
	Write-Host "> It is suggested to edit the Game.ini to your liking."
	$edit = Read-Host "> Do you want to edit Game.ini? y/n"
	if ($edit.ToLower() -eq "yes" -or $edit.ToLower() -eq "y")
	{
		notepad ".\longvinter-windows-server\Longvinter\Saved\Config\WindowsServer\Game.ini"
	}
	
	$TargetFile = "$PWD\longvinter-windows-server\LongvinterServer.exe"
	$ShortcutFile = "$PWD\Longvinter.lnk"
	$WScriptShell = New-Object -ComObject WScript.Shell
	$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
	$Shortcut.TargetPath = $TargetFile
	$Shortcut.Arguments = "-log"
	$Shortcut.Save()
	Write-Host "> Shortcut created."
	
	Write-Host "Adding firewall rules..."
	New-NetFirewallRule -DisplayName "LongvinterServer UDP" -Action Allow -Protocol UDP -Direction Inbound -LocalPort 7777, 27015, 27016 | Out-Null
	New-NetFirewallRule -DisplayName "LongvinterServer UDP" -Action Allow -Protocol UDP -Direction Outbound -LocalPort 7777, 27015, 2701 | Out-Null
	New-NetFirewallRule -DisplayName "LongvinterServer TCP" -Action Allow -Protocol TCP -Direction Inbound -LocalPort 27015, 27016 | Out-Null
	New-NetFirewallRule -DisplayName "LongvinterServer TCP" -Action Allow -Protocol TCP -Direction Outbound -LocalPort 27015, 27016 | Out-Null
	
	Write-Host "> Press enter to continue..." -NoNewLine
	$Host.UI.ReadLine()
	Write-Host ""
	Write-Host "You can now run the shortcut in the current directory."
}
else
{
	Write-Host "One or more checks failed. Cannot install Longvinter Server."
	Exit
}
