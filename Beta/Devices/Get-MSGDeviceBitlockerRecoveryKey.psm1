
function Get-MSGDeviceBitlockerRecoveryKey
{
    <#
    .SYNOPSIS
    Gets bitlocker recovery keys for device from Azure Active Directory

    .DESCRIPTION
    The Get-MSGDeviceBitlockerRecoveryKey cmdlet gets bitlocker recovery keys for device from Azure Active Directory

    .PARAMETER IncludeRecoveryKeys
    include associated recovery keys for bitlocker entries

    .PARAMETER DeviceId
    Specifies the DeviceId (not ObjectId) of a device  in Azure AD.

    .PARAMETER CountOnly
    Return the count of objects based on the specified query

    .EXAMPLE

    Get-MSGDeviceBitlockerRecoveryKey -DeviceId 38ac9774-5c82-4ee5-b5a8-5ff7e815c0a4 -CountOnly
    7

    .NOTES
    Requires an applicatioId with the relevant delegate permissions and membership in an elevated roles as defined in:
    https://learn.microsoft.com/en-us/graph/api/bitlockerrecoverykey-get?view=graph-rest-1.0

    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Device of the device.')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$DeviceId,

        [Parameter(
            Mandatory = $false)]
        [switch]$IncludeRecoveryKeys,

        [Parameter(
            Mandatory = $false)]
        [switch]$CountOnly
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }
        $baseURI = 'https://graph.microsoft.com/beta/informationProtection/bitlocker/recoveryKeys'
    }

    process
    {
        $queryURI = "{0}?`$filter=deviceId eq '{1}'" -f $baseURI, $deviceId
        $result = Invoke-SafeWebRequest -Method Get -Uri $queryURI -Headers $headers

        if ($CountOnly)
        {
            return $result.value.Count
        }

        foreach ($key in $result.value)
        {
            if ($IncludeRecoveryKeys)
            {
                $recoveryURI = "{0}/{1}?`$select=key" -f $baseURI, $key.Id
                $result = Invoke-SafeWebRequest -Method Get -Uri $recoveryURI -Headers $headers
                if ($null -ne $result.Key)
                {
                    Add-Member -InputObject $key -MemberType NoteProperty -Name 'recoveryKey' -Value $result.key
                }
            }
            $key
        }
    }
}
