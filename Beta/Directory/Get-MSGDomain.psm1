
function Get-MSGDomain
{
    <#
    .SYNOPSIS
    Return domain information

    .DESCRIPTION
    The Get-MSGDomains cmdlet gets a domain in Azure Active Directory

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER Top
    Specifies the maximum number of records to return

    .PARAMETER SearchString
    String to use as part of search.  SearchString support OData search values as well, see https://docs.microsoft.com/en-us/graph/query-parameters#using-search-on-directory-object-collections for details

    .PARAMETER Filter
    Specifies the OData filter statement. This parameter controls which objects are returned

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .PARAMETER All
    If true, return all items. If false, return the number of objects specified by the Top parameter

    .EXAMPLE
    Get-MSGDomain -DomainName microsoft.com

    Id            AuthenticationType IsDefault isInitial IsVerified
    --            ------------------ --------- --------- ----------
    microsoft.com Federated          False     False     True

    .LINK
    https://docs.microsoft.com/en-us/graph/api/domain-list?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding(DefaultParameterSetName = 'TopAll')]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Domain name')]
        [string]$DomainName,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Search',
            HelpMessage = 'Search criteria.')]
        [Parameter(ParameterSetName = 'Count')]
        [Parameter(ParameterSetName = 'TopAll')]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(Mandatory = $false,
            HelpMessage = 'OData query filter')]
        [Parameter(ParameterSetName = 'TopAll')]
        [Parameter(ParameterSetName = 'Search')]
        [Parameter(ParameterSetName = 'Count')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            HelpMessage = 'List of properties to return. Note that these are case sensitive')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Properties,

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
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "domains/$DomainName" -Filter $queryFilter
                break
            }

            { $PSItem -match 'topall|search' }
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'domains' -Filter $queryFilter -All:$All -CountOnly:$CountOnly
                break
            }
        }
    }
}
