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

### SETUP VARIABLES ###

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
        # Compact's query is verbose; only interested in the 3rd to last line of output
        $Directory_Status=@(Compact /q /s:$Directory | Select -Last 3 | Select -First 1 )
        $Directory_Status=$Directory_Status -Split '\s+'

        # If sizes match, data is uncompressed; proceed with compressing
        # First(0) 'word' is Data Payload Size. Ninth(8) 'word' is Size on Disk.
        if ( $Directory_Status[0] -eq $Directory_Status[8] ) {
            Compact /c /exe:$Compression_Method /s:$Directory
        }
        # Otherwise some data is compressed; check for uncompressed subdirectories
        else {
            $List_of_Subdirectories=@( Get-ChildItem -Directory -Name $Directory )
            Foreach( $Subdirectory in $List_of_Subdirectories ) {

                # Query each subdirectory to determine if it is already compressed
                $Query_Output=@( Compact /q /s:"$Directory\$Subdirectory" | Select -Last 3 | Select -First 1 )
                $Query_Output=$Query_Output -Split '\s+'

                # If sizes match, data is uncompressed; proceed with compressing
                if ( $Query_Output[0] -eq $Query_Output[8] ) {
                    Compact /c /exe:$Compression_Method /s:"$Directory\$Subdirectory"
                }
            }
        }
    }
}
else {
    Write-Warning 'Abort: No directories found to compress.'
    Exit 1
}

Exit
