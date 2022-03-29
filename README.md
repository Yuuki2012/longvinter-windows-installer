# Longvinter Windows Manager
PowerShell manager for Longvinter Windows Server

## Requirements
1. Administrator privileges
2. Windows 10+
3. PowerShell 5+ (tested with 5.X and 7.2)
4. Steam
5. Git + git-lfs

## Commands
```powershell
# Returns Steam Server ID, assuming the server has been ran at least once
.\Manager.ps1 getkey

# Updates the server
.\Manager.ps1 update

# Creates a backup of the saves and settings
.\Manager.ps1 backup

# Uninstalls the server
.\Manager.ps1 uninstall
```
> Running without arguments will install the server.

## License
[GNU GPLv3](https://choosealicense.com/licenses/gpl-3.0/)

#

*Script made by Yuuki / 第一#0001 @ Discord*

*Original repository on [GitHub](https://github.com/Yuuki2012/longvinter-windows-manager)*.