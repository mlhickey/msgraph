function Remove-MSGServicePrincipal
{
    <#
    .SYNOPSIS
    Remove service principal

    .DESCRIPTION
    The Remove-MSGServicePrincipal cmdlet will remove the specified serviceprincipa;

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .EXAMPLE
    Remove-MSGServicePrincipal -Id 49223a9d-ba1b-4260-90a2-4571e42823d7

    StatusCode  StatusDescription
    ----------  -----------------
    204         No Content

    .LINK
    https://docs.microsoft.com/en-us/graph/api/serviceprincipal-delete?view=graph-rest-beta&tabs=http

    #>
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id of the application")]
        [Alias("ObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id
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
        if ($PSCmdlet.ShouldProcess("$Id", "Delete serviceprincipal"))
        {
            Remove-MSGObject -Type serviceprincipal -Id $id
        }
    }
}
