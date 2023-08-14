function Get-MSPIMResource
{
    <#
    .SYNOPSIS
    Get current list of accessible resources

    .DESCRIPTION
    The Get-MSPIMResources cmdlet returns the current list of resources that the requestor has access to

    .EXAMPLE
    Get-MSPIMResource -Top 2

        Id                                   Type                                 DisplayName       Status RegisteredDateTime OnboardDateTime
        --                                   ----                                 -----------       ------ ------------------ ---------------
        453fa744-8104-40e9-8756-4a1c4292cd21 microsoft.insights/autoscalesettings autoscalesettings Active
        176bda47-42a4-42e7-a4a5-fc989cfceb57 Microsoft.KeyVault/vaults            gmm-kv-dev        Active

    .LINK
     https://docs.microsoft.com/en-us/graph/api/governanceresource-list?view=graph-rest-beta&tabs=http
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    [CmdletBinding(DefaultParameterSetName = 'TopAll')]
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the specific resource')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Search',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the specific resource')]
        [string]$SearchString,

        [Parameter(ParameterSetName = 'TopAll')]
        [ValidateNotNullOrEmpty()]
        [int]$Top = 100,

        [Parameter(ParameterSetName = 'TopAll')]
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
        #$null= $PSBoundParameters.Remove("SearchString")
        $queryFilter = ProcessBoundParams -paramList $PSBoundParameters
    }

    process
    {
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'id'
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "privilegedAccess/azureResources/resources/$id" -Filter $queryFilter -ObjectName 'MSPIM'
                break
            }

            'topall'
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'privilegedAccess/azureResources/resources' -Filter $queryFilter -ObjectName 'MSPIM' -All:$All
                break
            }
        }
    }
}
