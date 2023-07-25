<#
 https://learn.microsoft.com/en-us/graph/api/reportroot-list-appcredentialsigninactivities?view=graph-rest-beta&tabs=http
 #>
function Get-MSGAppCredentialSignInActivities
{
    [CmdletBinding(DefaultParameterSetName = 'TopAll')]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'KeyId',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Key Id')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$KeyId,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'ActivityId',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'ActivityId Id')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$ActivityId,

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
        #  https://graph.microsoft.com/beta/reports/appCredentialSignInActivities?
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'keyid'
            {
                $queryFilter = "id eq '$id'" + $queryFilter
                Get-MSGObject -Type "reports/appCredentialSignInActivities?`$filter=keyId eq '$KeyId'"
                break
            }
            'appid'
            {
                $queryFilter = "id eq '$id'" + $queryFilter
                Get-MSGObject -Type "reports/appCredentialSignInActivities?`$filter=appId eq '$AppId'"
                break
            }
            'activityid'
            {
                $queryFilter = "id eq '$id'" + $queryFilter
                Get-MSGObject -Type "reports/appCredentialSignInActivities/$activityId'"
                break
            }
            { $PSItem -match 'topall|search' }
            {

                Get-MSGObject -Type 'reports/appCredentialSignInActivities' -Filter $queryFilter -All:$All
                break
            }
        }
    }
}
