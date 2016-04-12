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
    Version:      1.2
    Author:       Ian Leonard
    Copyright:    2016
    License:      GNU General Public License v3.0
    Release Date: 2016-04-11

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
            Write-Error 'Abort: '$Test_Object' is not a directory.'
            Exit 1
        }
    }
}

# Report-DataSizeAndOnDisk:
# Parse Compact.exe's query output and convert output strings to integers
function Report-DataSizeAndOnDisk( $Test_Object ) {
    # Compact's query is verbose; only interested in the 3rd to last line of output
    $Directory_Status=@(Compact /q /s:$Test_Object | Select -Last 3 | Select -First 1 )
    $Directory_Status=$Directory_Status -Split '\s+'
    # First(0) 'word' is Data Size. Ninth(8) 'word' is Size on Disk.
    # Convert Strings to Numbers (long == int64)
    $Directory_Status[0]=$Directory_Status[0] -replace '[,]'
    [long]$Directory_Status[0]
    $Directory_Status[8]=$Directory_Status[8] -replace '[,]'
    [long]$Directory_Status[8]
}

### MAIN ###

Add-DirectoryToList $Steam_Game_Directory $Origin_Game_Directory

# Compress each directory in turn
if ( $List_Of_Directories.length -ne 0 ) {
    Foreach( $Directory in $List_Of_Directories ) {

        # Query each directory to determine if it is already compressed
        $Directory_Size = Report-DataSizeAndOnDisk $Directory
        # Directory_Size[0] == Data Size, Directory_Size[1] == Size on Disk

        # If sizes match, data is uncompressed; proceed with compressing
        if ( $Directory_Size[0] -eq $Directory_Size[1] -And $Directory_Size[0] -ne 0 ) {
            Compact /c /exe:$Compression_Method /s:$Directory
        }
        # Otherwise some data is compressed; check for uncompressed subdirectories
        else {
            $List_of_Subdirectories=@( Get-ChildItem -Directory -Name $Directory )
            Foreach( $Subdirectory in $List_of_Subdirectories ) {

                # Query each subdirectory to determine if it is already compressed
                $Directory_Size = Report-DataSizeAndOnDisk $Directory\$Subdirectory
                # Directory_Size[0] == Data Size, Directory_Size[1] == Size on Disk

                # If sizes match, data is uncompressed; proceed with compressing
                if ( $Directory_Size[0] -eq $Directory_Size[1] -And $Directory_Size[0] -ne 0 ) {
                    Compact /c /exe:$Compression_Method /s:$Directory\$Subdirectory
                }
            }
        }
    }
}
else {
    Write-Error 'Abort: No directories found to compress.'
    Exit 1
}

Exit