function Remove-MSGServicePrincipalKeyCredential
{
    <#
    .SYNOPSIS
    Remove credential from specifed service principal by keyId

    .DESCRIPTION
    The Remove-MSGServicePrincipalKeyCredential cmdlet will remove credential identified by keyId from specifed service principal

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER KeyId
    Specifies the keyId of the credential to remove

    .LINK
    https://docs.microsoft.com/en-us/graph/api/serviceprincipal-removekey?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    [OutPutType('System.Collections.Hashtable')]
    param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the servicePrincipal')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Key credential keyId to remove')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$keyId
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
        $arg = $res = $null
        $res = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "servicePrincipals/$id" -Filter "`$select=keyCredentials"

        if ($null -eq $res -or $res.StatusCode -ge 400)
        {
            Write-Error "Couldn't resolve $keytpe for $id"
            return $res
        }

        $pwdList = $res.KeyCredentials
        if (($null -ne $pwdList) -and [bool]($pwdList.Where( { $_.KeyId -eq $keyId })))
        {
            $arg = [psobject]@{
                'keyCredentials' = @($pwdList.Where( { $_.KeyId -ne $keyId }))
            }
        }
        else
        {
            Write-Verbose "keyCredentials credential $keyId not found for servicePrincipals resource $id"
            return @{
                StatusCode = [System.Net.HttpStatusCode]::NotFound
            }
        }

        if ($null -ne $arg -and $PSCmdlet.ShouldProcess("$Id", 'Delete keyCredentials'))
        {
            Set-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type servicePrincipals -Id $id -Body $arg
        }
    }
}
