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

#Execute command on remote system using WMI commandline executable
if(![String]::IsNullOrEmpty($Username) -and $Password -ne $null) {
    #Run with explicit credentials
    $Username = "administrator@lab.net"
    $Password = "1qaz!QAZ"
    $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $SecurePassword

    Invoke-WmiMethod -Class "WIN32_PROCESS" -Name "Create" -ArgumentList $Command -ComputerName $Target -Credential $Credential
} else {
    #Run with impersonation
    Invoke-WmiMethod -Class "WIN32_PROCESS" -Name "Create" -ArgumentList $Command -ComputerName $Target
}