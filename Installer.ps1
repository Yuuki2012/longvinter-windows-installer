#Requires -RunAsAdministrator

<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.196
	 Created on:   	2022/03/25 05:55:13 PM
	 Created by:   	Yuuki2012
	 Organization: 	Fantastiic
	 Filename:     	Installer.ps1
	===========================================================================
	.DESCRIPTION
		Installer for Longvinter-windows-server.
#>

$global:check = 0

function check_git-lfs
{
	Try
	{
		git-lfs | Out-Null
		Write-Host "[" -NoNewline
		Write-Host "✓" -NoNewline -ForegroundColor Green
		Write-Host "]" -NoNewline
		
		Write-Host " Git-LFS is installed"
		$global:check += 1
	}
	Catch [System.Management.Automation.CommandNotFoundException]
	{
		Write-Host "[" -NoNewline
		Write-Host "X" -NoNewline -ForegroundColor Red
		Write-Host "]" -NoNewline
		
		Write-Host " Git-LFS is not installed."
	}
}
function check_software($app)
{
	$installed32 = (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -eq $app }) -ne $null
	$installed64 = (Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | where { $_.DisplayName -eq $app }) -ne $null
	
	If ($installed32 -or $installed64)
	{
		Write-Host "[" -NoNewline
		Write-Host "✓" -NoNewline -ForegroundColor Green
		Write-Host "]" -NoNewline

		Write-Host " $app is installed."
		$global:check += 1
	}
	Else
	{
		Write-Host "[" -NoNewline
		Write-Host "X" -NoNewline -ForegroundColor Red
		Write-Host "]" -NoNewline
		
		Write-Host " $app is not intsalled."
	}
}
function check_ram ($in)
{
	$total = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).sum /1gb

	If ($total -gt $in)
	{
		Write-Host "[" -NoNewline
		Write-Host "✓" -NoNewline -ForegroundColor Green
		Write-Host "]" -NoNewline
		
		Write-Host " $total GB RAM detected."
		$global:check += 1
	}
	Else
	{
		Write-Host "[" -NoNewline
		Write-Host "X" -NoNewline -ForegroundColor Red
		Write-Host "]" -NoNewline
		
		Write-Host " $in GB RAM detected. You need at least 3 GB."
	}
}
function check_arch
{
	$arch = (Get-CIMInstance CIM_OperatingSystem).OSArchitecture
	
	If ($arch -eq "64-bit")
	{
		Write-Host "[" -NoNewline
		Write-Host "✓" -NoNewline -ForegroundColor Green
		Write-Host "]" -NoNewline
		
		Write-Host " $arch OS detected."
		$global:check += 1
	}
	Else
	{
		Write-Host "[" -NoNewline
		Write-Host "X" -NoNewline -ForegroundColor Red
		Write-Host "]" -NoNewline
		
		Write-Host " $arch OS detected. You need a 64-bit system to install Longvinter Server."
	}
}
function getkey
{
	$exists = Test-Path -Path ".\longvinter-windows-server\Longvinter\Saved\Logs\Longvinter.log" -PathType Leaf
	
	IF ($exists)
	{
		Write-Host ([uint64](Select-String -Pattern "0[xX][0-9a-fA-F]{15}" -Path ".\longvinter-windows-server\Longvinter\Saved\Logs\Longvinter.log").Matches.groups[0].value) -NoNewline -ForegroundColor Green
	}
	Else
	{
		Write-Host "[" -NoNewline
		Write-Host "X" -NoNewline -ForegroundColor Red
		Write-Host "]" -NoNewline -ForegroundColor Gray
		
		Write-Host " Longvinter.log not found. Please run the server first."
	}
	
	Exit
}
function update
{
	# TODO: Implement git updating
}

If ($args.Count -eq 1)
{
	If ($args[0].ToString().ToLower() -eq "getkey")
	{
		getkey
	}
	Elseif ($args[0].ToString().ToLower() -eq "update")
	{
		update
	}
	Exit
}

Write-Host "Please wait while everything is being checked..."
check_software("Steam")  # argument is program name.
check_software("Git")
check_git-lfs
check_ram(3)  # argument is amount of (required) RAM in GB.
check_arch

If ($check -eq 5)
{
	Write-Host "Cloning Longvinter Windows Server repository..."
	git clone -q https://github.com/Uuvana-Studios/longvinter-windows-server.git
	
	Move-Item ".\longvinter-windows-server\Longvinter\Saved\Config\WindowsServer\Game.ini.default" ".\longvinter-windows-server\Longvinter\Saved\Config\WindowsServer\Game.ini"
	Write-Host "> It is suggested to edit the Game.ini to your liking."
	$edit = Read-Host "> Do you want to edit Game.ini? y/n"
	If ($edit.ToLower() -eq "yes" -or $edit.ToLower() -eq "y")
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
Else
{
	Write-Host "One or more checks failed. Cannot install Longvinter Server."
	Exit
}
