function Set-MSGServicePrincipal
{
    <#
    .SYNOPSIS
    Set properties for service principal

    .DESCRIPTION
    The Set-MSGServicePrincipal cmdlet gets applications is used to set properties for for the specified service principal.  These include:

    AccountEnabled
    AppRoleAssignmentRequired
    DisplayName

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER AccountEnabled
    Specifies whether service principal is enabled

    .PARAMETER AppRoleAssignmentRequired
    Specified with role assignment is required

    .PARAMETER DisplayName
    Specifies the display name of the group

    .EXAMPLE
    Set-MSGServicePrincipal -Id 9a19415d-5d2c-410b-b6c3-ccd0daa3f240 -AccountEnabled $true

    .LINK
    https://docs.microsoft.com/en-us/graph/api/serviceprincipal-update?view=graph-rest-beta&tabs=http
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id of the servicePrincipal.")]
        [Alias("ObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [bool]$AccountEnabled,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [bool]$AppRoleAssignmentRequired,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$DisplayName

    )
    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw "You must call the Connect-MSG cmdlet before calling any other cmdlets"
        }
    }

    process
    {
        Write-Warning "Implementation TBD"
        if ($PSCmdlet.ShouldProcess("$Id", "Set service principal"))
        {}
    }
}
