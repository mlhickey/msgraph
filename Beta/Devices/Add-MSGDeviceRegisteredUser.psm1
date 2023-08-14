function Add-MSGDeviceRegisteredUser
{
    <#
    .SYNOPSIS
    Sets the device owners/users from Azure Active Directory for the specified

    .DESCRIPTION
    The Add-MSGDeviceRegisteredUser cmdlet sets the owners/registered users for the specified device

    .PARAMETER Id
    Specifies the Id (ObjectId) of a device  in Azure AD.

    .PARAMETER RefObjectId
    Specifies the ID of the Active Directory object to add

    .LINK
     https://docs.microsoft.com/en-us/graph/api/device-post-registeredusers?view=graph-rest-1.0&tabs=http

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'ObjectId of the device.')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $true,
            Position = 1,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'RefObjectId of the user to add')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$RefObjectId
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }
    }

    process
    {
        $body = @{
            '@odata.id' = "https://graph.microsoft.com/$($MSGAuthInfo.GraphVersion)/directoryObjects/$RefObjectId"
        }
        Set-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Method POST -Type "devices/$Id/registeredUsers" -Body $body
    }
}

