
function Enable-MSGDevice
{
    <#
    .SYNOPSIS
    Enables the specified device

    .DESCRIPTION
    The Enable-MSGDevice cmdlet to enable the specified device

    .PARAMETER Id
    Specifies the Id (ObjectId) of a device  in Azure AD.

    .PARAMETER FullResponse
    Return the full Graph response body as an object

    .LINK
     https://docs.microsoft.com/en-us/graph/api/device-update?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ObjectId of the device.")]
        [Alias("ObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }
    }

    process
    {
        Set-MSGObject  -Debug:$DebugPreference -Verbose:$VerbosePreference -Type devices -Id $Id -Method PATCH -Body @{ accountEnabled = $true }
    }
}
