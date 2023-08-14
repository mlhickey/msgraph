function Get-MSGRiskyUser
{
    <#

    .SYNOPSIS
    Gets risk events

    .DESCRIPTION
    The Get-MSGRiskyUsers cmdlet gets associated risk events

    .PARAMETER Id
    Specifies the Id of an event

    .PARAMETER RiskLevel
    Specifies the risk level to return - Low, Medium or High

    .LINK
    https://docs.microsoft.com/en-us/graph/api/riskyusers-list?view=graph-rest-beta&tabs=http
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'ObjectId of the group')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $False,
            HelpMessage = 'Risk level: Low, Medium or High')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(
            'Low',
            'Medium',
            'High'
        )]
        [string]$RiskLevel,
        [switch]$All
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }
    }

    process
    {
        $queryString = 'riskyUsers'
        if (-not [string]::IsNullOrEmpty($id))
        {
            $queryString = += '/{0}' -f $id
        }

        if (-not [string]::IsNullOrEmpty($RiskLevel))
        {
            $filter = "`riskLevel eq microsoft.graph.riskLevel'{0}'" -f $RiskLevel.ToLower()
        }
        Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type $queryString -Filter $filter -All:$All
    }
}
