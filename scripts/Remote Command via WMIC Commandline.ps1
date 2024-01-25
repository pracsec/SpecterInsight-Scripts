param(
    [Parameter(ParameterSetName="Impersonate", Mandatory=$True, HelpMessage="The IP address or hostname of the system to run the command.")]
    [Parameter(ParameterSetName="Username and Password", Mandatory=$True, HelpMessage="The IP address or hostname of the system to run the command.")]
    [ValidateNotNullOrEmpty]
    [string]$Target,

    [Parameter(ParameterSetName="Username and Password", Mandatory=$True, HelpMessage="The local or domain username to authenticate with.")]
    [ValidateNotNullOrEmpty]
    [string]$Username,

    [Parameter(ParameterSetName="Username and Password", Mandatory=$True, HelpMessage="The password for the specified user.")]
    [ValidateNotNullOrEmpty]
    [string]$Password,

    [Parameter(ParameterSetName="Impersonate", Mandatory=$True, HelpMessage="The command to run on the target system.")]
    [Parameter(ParameterSetName="Username and Password", Mandatory=$True, HelpMessage="The command to run on the target system.")]
    [ValidateNotNullOrEmpty]
    [string]$Command
)

#Shell escape any embedded slashes
$Command = $Command.Replace('\', '\\');
$Command = $Command.Replace('"', '\"');

#Execute command on remote system using WMI commandline executable
if(![String]::IsNullOrEmpty($Username) -and $Password -ne $null) {
    #Run with explicit credentials
    wmic.exe /node:$Target /user:$Username /password:$Password process call create $Command
} else {
    #Run with impersonation
    wmic.exe /node:$Target process call create $Command
}