function Remove-MSGRiskyUser
{
    <#
    .SYNOPSIS
    Dismisses risky users

    .DESCRIPTION
    The Remove-MSGRiskyUser cmdlet dismisses associated risky users

    .PARAMETER UserIdList
    Specifies the list of userIds to dismiss

    .PARAMETER FullResponse
    Return the full Graph response body as an object

    .LINK
    https://docs.microsoft.com/en-us/graph/api/riskyusers-dismiss?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'List of user IDs to dismiss')]
        [string[]]$UserIdList
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
        $queryString = 'riskyUsers/dismiss'
        $body = @{ 'userIds' = $UserIdList }
        if ($PSCmdlet.ShouldProcess("$Id", 'Remove risky user'))
        {
            Set-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type $queryString -Body $body -Method POST
        }
    }
}
