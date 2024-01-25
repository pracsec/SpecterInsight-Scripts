param(
    [Parameter(Mandatory=$True, HelpMessage="The path to a file or directory.")]
    [ValidateNotNullOrEmpty]
    [string]$Path = 'C:\Users\',

    [Parameter(Mandatory=$True, HelpMessage="True to recursively list files and folders in subdirectories.")]
    [ValidateNotNullOrEmpty]
    [bool]$Recurse = $true,

    [Parameter(Mandatory=$True, HelpMessage="A wildcard filter to identify which file system entries to select.")]
    [ValidateNotNullOrEmpty]
    [string]$Filter = "*"
)

$entries = Get-ChildItem -Path $Path -Filter $Filter -Recurse:$Recurse -ErrorAction SilentlyContinue;
$entries | Select Length,PSIsContainer,Extension,CreationTimeUtc,LastAccessTimeUtc,LastWriteTimeUtc,FullName | Sort-Object LastWriteTimeUtc -Descending