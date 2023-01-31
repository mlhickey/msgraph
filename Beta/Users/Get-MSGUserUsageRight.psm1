function Get-MSGUserUsageRight
{
    <#
    .SYNOPSIS
    Get information about various directory objects

    .DESCRIPTION
    The Get-MSGUserUsageRight cmdlet retrieves a list of usageRight objects for a given user

    .PARAMETER Id
    Specifies the ID (as a UPN or ObjectId) of a user in Azure AD

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER All
    If true, return all items. If false, return the number of objects specified by the Top parameter

    .LINK
    https://docs.microsoft.com/en-us/graph/api/user-list-usagerights?view=graph-rest-beta&tabs=http

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Either the ObjectId or the UserPrincipalName of the User.")]
        [Alias("ObjectId", "UserPrincipalName")]
        [string]$Id,

        [Parameter(Mandatory = $false,
            HelpMessage = "OData query filter")]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(Mandatory = $false,
            HelpMessage = "List of properties to return. Note that these are case sensitive")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

        [ValidateNotNullOrEmpty()]
        [int]$Top = 100,

        [Parameter(Mandatory = $false)]
        [switch]$All
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
        $id = [uri]::EscapeDataString($id)
        $typeString = "users/{0}/usageRights" -f $Id

        $res = Get-MSGObject -Type $typeString -Filter $queryFilter -All:$All
        # do fixup where there are multiple datatypes
        if ($res.StausCode -lt 300)
        {
            $res | ForEach-Object { $_.PSOBject.TypeNames.Insert(0, "MSGraph.objects") }
        }
        $res
    }
}
