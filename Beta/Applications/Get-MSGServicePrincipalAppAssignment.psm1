function Get-MSGServicePrincipalAppRoleAssignedTo
{
    <#
    .SYNOPSIS
    Get serviceprincipal application assignments

    .DESCRIPTION
    The Get-MSGServicePrincipalAppRoleAssignedTo cmdlet gets the application assignment information for the specified serviceprincipal(s)

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER AppId
    Specifies the service principal application Id of an service principal in Azure AD.

    .PARAMETER SearchString
    String to use as part of search.  SearchString support OData search values as well, see https://docs.microsoft.com/en-us/graph/query-parameters#using-search-on-directory-object-collections for details

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER All
    If true, return all application objects. If false, return the number of objects specified by the Top parameter

    .LINK
    https://docs.microsoft.com/en-us/graph/api/serviceprincipal-list-approleassignments?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding(DefaultParameterSetName = "Id")]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ObjectId of the object")]
        [Alias("ObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
[string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = "AppId",
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "AppId of the associated application")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
[string]$AppId,

        [Parameter(Mandatory = $false,
            ParameterSetName = "Search",
            HelpMessage = "Partial/complete displayname of the object.")]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(Mandatory = $false,
            HelpMessage = "OData query filter")]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(Mandatory = $false,
            HelpMessage = "List of properties to return. Note that these are case sensitive")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties = @("id"),

        [Parameter(ParameterSetName = "TopAll")]
        [Parameter(ParameterSetName = "Search")]
        [int]$Top = 100
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

        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            "id"
            {
                $res = Get-MSGObject -Type "servicePrincipals/$id" -Filter $queryFilter
                break
            }
            "appid"
            {

                if ([string]::IsNullOrEmpty($queryFilter))
                {
                    $queryFilter = "Appid eq '$AppId'"
                }
                else
                {
                    $queryFilter = @("Appid eq '$AppId'", $queryFilter) -join '&'
                }
                $res = Get-MSGObject -Type "servicePrincipals" -Filter $queryFilter
                break
            }
            "search"
            {
                $res = Get-MSGObject -Type "servicePrincipals" -Filter $queryFilter -All:$All
                break
            }
            default
            {
                Write-Warning "You must specify either an ObjectId or a searchable string"
                return $null
            }
        }
        if ($res.StatusCode -ge 400) { return $res }
        foreach ($r in $res)
        {
            Get-MSGObject -Type "servicePrincipals/$($r.id)/appRoleAssignedTo" -All
        }
    }
}
