function Get-MSPIMGroup
{
    <#
    .SYNOPSIS
    Get current list of PIM groups

    .DESCRIPTION
    The Get-MSPIMResources cmdlet returns the current list of groups that the requestor has access to

    .EXAMPLE
    Get-MSPIMGroup -Top 2

        Id                                   DisplayName                        Type     Status
        --                                   -----------                        ----     ------
        00225420-6f7a-466b-8397-0498445b148d ADO-343-OUTSOURCE_ENDEAVOR1-PA-JIT Security Active
        004ef85b-94c2-4d97-95f9-705df810bff9 ADO-Office-Test2-PkgCon-JIT        Office   Active

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
            ParameterSetName = 'Filter',
            HelpMessage = 'OData query filter')]
        [ValidateNotNullOrEmpty()]
        [Parameter(ParameterSetName = 'Id')]
        [Parameter(ParameterSetName = 'Count')]
        [Parameter(ParameterSetName = 'TopAll')]
        [string]$Filter,

        [Parameter(ParameterSetName = 'TopAll')]
        [ValidateNotNullOrEmpty()]
        [int]$Top = 100,

        [Parameter(ParameterSetName = 'Count')]
        [switch]$CountOnly,

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
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "privilegedAccess/aadGroups/resources/$id" -Filter $queryFilter -ObjectName 'MSPIM'
                break
            }

            'topall'
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'privilegedAccess/aadGroups/resources' -Filter $queryFilter -ObjectName 'MSPIM' -All:$All
                break
            }
            'count'
            {
                Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'privilegedAccess/aadGroups/resources' -Filter $queryFilter -ObjectName 'MSPIM' -CountOnly
            }
        }
    }
}
