function Get-MSGGroupAppAssignment
{
    <#
    .SYNOPSIS
    Get application assignments

    .DESCRIPTION
    The Get-MSGGroupAppAssignment cmdlet gets the application assignment information for the specified group(s)

    .PARAMETER Id
    Specifies the id (ObjectId) of a group in Azure Active Directory

    .PARAMETER SearchString
    String to use as part of search.  SearchString support OData search values as well, see https://docs.microsoft.com/en-us/graph/query-parameters#using-search-on-directory-object-collections for details

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER All
    If true, return all items. If false, return the number of objects specified by the Top parameter

    .LINK
    https://docs.microsoft.com/en-us/graph/api/approleassignment-get?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding(DefaultParameterSetName = 'Id')]
    param(
        # UserprincipalName or objectId
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'ObjectId of the group.')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Search',
            HelpMessage = 'Partial/complete displayname of the group.')]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(Mandatory = $false,
            HelpMessage = 'OData query filter')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [ValidateNotNullOrEmpty()]
        [int]$Top = 100,

        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [Parameter(Mandatory = $false)]
        [switch]$All
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }
        $queryFilter = ProcessBoundParams -paramList $PSBoundParameters
    }

    process
    {
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'id'
            {
                $res = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "groups/$id" -Filter $queryFilter
                break
            }
            'osearch'
            {
                $res = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'groups' -SearchString "startswith(displayName,'$SearchString')" -Filter $queryFilter -All:$All
                break
            }
            'search'
            {
                $res = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'groups' -Filter $queryFilter -All:$All
                break
            }
            default
            {
                Write-Warning 'You must specify either a group ObjectId or searchable name'
                return $null
            }
        }
        if ($res.StatusCode -ge 400)
        {
            return $res 
        }
        foreach ($r in $res)
        {
            Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "groups/$($r.id)/appRoleAssignments" -Filter $queryFilter -All:$All
        }
    }
}
