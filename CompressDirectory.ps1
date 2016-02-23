<#
.SYNOPSIS
    Compress designated static directories listed in script.

.DESCRIPTION
    Uses transparent filesystem compression tools found in Windows 10 (and 
    Windows Server 2016?) to compress directories listed in the Setup Variables
    section.

    This script is intended to be used as a scheduled task, or launched on 
    command, as files created since the last running of this script will not be
    compressed automatically.

    Do not use on the Windows system directory or system will not boot.

.INPUTS
    None

.OUTPUTS
    None

.NOTES
    Version:      1.0
    Author:       Ian Leonard
    Copyright:    2016
    License:      GNU General Public License v3.0
    Release Date: 2016-02-09

.LINK
    https://github.com/antonlacon/powershell-scripts

#>

### Setup Variables ###

# Directories to compress
$Steam_Game_Directory = 'C:\Program Files (x86)\Steam\SteamApps\common'
$Origin_Game_Directory = 'C:\Program Files (x86)\Origin Games'

# Compression methods: xpress4k, xpress8k, xpress16k, lzx (fastest to slowest)
$Compression_Method = 'xpress16k'

### HELPER FUNCTIONS ###

# Empty array to start list
$List_Of_Directories = @()

# Add-DirectoryToList:
# Check passed arguments are directories and add to list of directories if so
function Add-DirectoryToList {
    Foreach ( $Test_Object in $Args ) {
        if ( (Get-Item $Test_Object) -is [System.IO.DirectoryInfo] ) {
            $Script:List_Of_Directories += $Test_Object
        }
        else {
            Write-Warning 'Abort: '$Test_Object' is not a directory.'
            Exit 1
        }
    }
}

### MAIN ###

Add-DirectoryToList $Steam_Game_Directory $Origin_Game_Directory

# Compress each directory in turn
if ( $List_Of_Directories.length -ne 0 ) {
    Foreach( $Directory in $List_Of_Directories ) {
        Compact /c /exe:$Compression_Method /s:$Directory
    }
}
else {
    Write-Warning 'Abort: No directories found to compress.'
    Exit 1
}

Exit