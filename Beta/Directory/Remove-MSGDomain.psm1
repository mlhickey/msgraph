
function Remove-MSGDomain
{
    <#
    .SYNOPSIS
    Remove a domain

    .DESCRIPTION
     The Remove-AzureADDomain cmdlet removes a domain from Azure Active Directory (AD)

    .PARAMETER Name
    Name of the domain

    .LINK
    https://docs.microsoft.com/en-us/graph/api/domain-delete?view=graph-rest-beta&tabs=http
    #>

    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Name of the domain.')]
        [string]$Name
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
        if ($PSCmdlet.ShouldProcess("$Name", 'Remove domain'))
        {
            Remove-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'domains' -Id $Name
        }
    }
}
