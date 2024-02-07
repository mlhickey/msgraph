<#
 https://learn.microsoft.com/en-us/graph/api/reportroot-list-servicePrincipalSignInActivities?view=graph-rest-beta&tabs=http
 #>
function Get-MSGservicePrincipalSignInActivities
{
    [CmdletBinding(DefaultParameterSetName = 'TopAll')]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'AppId',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Application  Id')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$AppId,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Search',
            HelpMessage = 'Partial/complete displayname of the object.')]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(Mandatory = $false,
            HelpMessage = 'OData query filter')]
        [ValidateNotNullOrEmpty()]
        [string]$Filter,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(1, 30)]
        [string]$ReportPeriod = '7',

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
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }
        $queryFilter = ProcessBoundParams -paramList $PSBoundParameters
    }

    process
    {
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'appid'
            {
                $queryFilter = "id eq '$id'" + $queryFilter
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "reports/servicePrincipalSignInActivities?`$filter=appId eq '$AppId'"
                break
            }
            { $PSItem -match 'topall|search' }
            {

                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'reports/servicePrincipalSignInActivities' -Filter $queryFilter -All:$All
                break
            }
        }
    }
}
