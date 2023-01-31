function Remove-MSGConditionalAccessPolicy
{
    <#
    .SYNOPSIS
    Removes the specified  Azure Conditional Access policies

    .DESCRIPTION
    The Remove-MSGConditionalAccessPolicy cmdlet will remove the conditional access policy by id

    .PARAMETER Id
    Specifies the Id (ObjectId) of a conditional access policy in Azure AD.

    .LINK
     https://docs.microsoft.com/en-us/graph/api/conditionalaccesspolicy-delete?view=graph-rest-beta&tabs=http

    #>
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "ObjectId of the policy.")]
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

        if ($PSCmdlet.ShouldProcess("$Id", "Remove CA policy"))
        {
            Remove-MSGObject -Type "conditionalAccess/policies" -Id $id
        }
    }
}
