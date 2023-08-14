function Get-MSGServicePrincipalOwnedObject
{
    <#
    .SYNOPSIS
    Returns a list of OwnedObjects for the specified service principal id.

    .DESCRIPTION
    The Get-MSGServicePrincipalOwnedObject cmdlet teturns a list of OwnedObjects for the specified service principal id.

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

     .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .EXAMPLE
    Get-MSGServicePrincipalOwnedObject -Id 447bfab7-577d-4a4b-bf38-c27d93bbd5fd

    Id                                   AppId                                DisplayName
    --                                   -----                                -----------
    d9e445e3-afb6-4ba1-a6c8-81a43e99da71 7a875fc7-be13-4e84-a468-1c3ad5ec274e  _nistar_test
    bd4136eb-55f4-4db2-a368-aed60b492f41 eff5d7ea-5ece-4390-af91-d874a3895276 nistar_test
    ad15b928-b79a-49a0-a250-328a299af4e8                                      __MSPS__

    .LINK
    https://docs.microsoft.com/en-us/graph/api/serviceprincipal-list-ownedobjects?view=graph-rest-beta&tabs=http
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the servicePrincipal')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            HelpMessage = 'List of properties to return. Note that these are case sensitive')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }

        if (-not [string]::IsNullOrEmpty($properties))
        {
            $propFilter = "`$select="
            $propFilter += $properties -join ','
        }
    }

    process
    {
        Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "servicePrincipals/$id/ownedObjects" -Filter $propFilter
    }
}
