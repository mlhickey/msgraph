function Get-MSGServicePrincipalOwner
{
    <#
    .SYNOPSIS
    Returns a list of owners for the specified service principal id.

    .DESCRIPTION
    The Get-MSGServicePrincipalOwner cmdlet teturns a list of owners for the specified service principal id.

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER Filter
    Specifies the oData filter statement. This parameter controls which objects are returned

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .EXAMPLE
    Get-MSGServicePrincipalOwners -Id 3773d910-6134-4574-af1a-4034c6200768

    Id                                   DisplayName             UserPrincipalName      UserType
    --                                   -----------             -----------------      --------
    74f9ecc7-6d2d-4d97-9762-865df346f2ca Mike Hickey              xxxxxxx@microsoft.com Member

    .LINK
     https://docs.microsoft.com/en-us/graph/api/serviceprincipal-list-owners?view=graph-rest-beta&tabs=http
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id of the servicePrincipal")]
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
        [string[]]$Properties,

        [Parameter(Mandatory = $false)]
        [int]$Top = 100,

        [Parameter(Mandatory = $false)]
        [switch]$All,

        [Parameter(Mandatory = $false)]
        [switch]$AdvancedQuery,

        [Parameter(Mandatory = $false)]
        [switch]$CountOnly
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
        Get-MSGObject -Type "servicePrincipals/$id/owners" -Filter $queryFilter
    }
}
