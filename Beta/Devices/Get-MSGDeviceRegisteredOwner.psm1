function Get-MSGDeviceRegisteredOwner
{
    <#
    .SYNOPSIS
    Gets the device owners from Azure Active Directory for the specified

    .DESCRIPTION
    The Get-MSGDeviceRegisteredOwners cmdlet retrieves the owners for the specified device

    .PARAMETER Id
    Specifies the Id (ObjectId) of a device  in Azure AD.

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .EXAMPLE
    Get-MSGDevice -SearchString futaleufa  -Properties id | Get-MSGDeviceRegisteredUser -Properties displayName

    Id                                   DisplayName UserPrincipalName     UserType
    --                                   ----------- -----------------     --------
    f839606d-4143-4ed4-a049-56c26049a343 Mike Hickey mhickey@microsoft.com
    f839606d-4143-4ed4-a049-56c26049a343 Mike Hickey mhickey@microsoft.com

    .LINK
     https://docs.microsoft.com/en-us/graph/api/device-list-registeredowners?view=graph-rest-1.0&tabs=http

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
        [string]$Id,

        [Parameter(Mandatory = $false,
            HelpMessage = "OData query filter")]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(Mandatory = $false,
            HelpMessage = "List of properties to return. Note that these are case sensitive")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }
        $queryFilter = ProcessBoundParams -paramList $PSBoundParameters
    }

    process
    {
        Get-MSGObject -Type "devices/$Id/registeredOwners" -Filter $queryFilter
    }
}
