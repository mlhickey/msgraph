Connect-AzAccount
$hostname = $(hostname)
$ver = '1.0'

$VMInfo = Get-AzVM -Name $hostname
$location = $VMInfo.Location
$ResourceGroupName = $VMInfo.ResourceGroupName

Set-AzVMExtension -Name AzureMonitorWindowsAgent `
    -ExtensionType AzureMonitorWindowsAgent `
    -Publisher Microsoft.Azure.Monitor `
    -ResourceGroupName $ResourceGroupName `
    -VMName $hostname -Location $Location `
    -TypeHandlerVersion $Ver -EnableAutomaticUpgrade $true