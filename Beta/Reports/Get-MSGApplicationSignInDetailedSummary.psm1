<#
 https://docs.microsoft.com/en-us/graph/api/applicationsigninsummary-get?view=graph-rest-beta&tabs=http
 #>
function Get-MSGApplicationSignInDetailedSummary
{
    [CmdletBinding(DefaultParameterSetName = 'TopAll')]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Application Id of alert to retrieve, not the object ID')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

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
                $queryFilter = "id eq '$id'" + $queryFilter
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "reports/applicationSignInDetailedSummary(period='D${ReportPeriod}')" -Filter $queryFilter
                break
            }
            { $PSItem -match 'topall|search' }
            {

                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "reports/getAzureADApplicationSignInSummary(period='D${ReportPeriod}')" -Filter $queryFilter -All:$All
                break
            }
        }
    }
}
