function Remove-MSGApplicationPasswordCredential
{
    <#
    .SYNOPSIS
    Remove credential from specifed application by keyId

    .DESCRIPTION
    The Remove-MSGApplicationPasswordCredential cmdlet will remove credential identified by keyId from specifed application

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER KeyId
    Specifies the keyId of the credential to remove

    .LINK
    https://docs.microsoft.com/en-us/graph/api/application-removepassword?view=graph-rest-beta&tabs=http
    #>
    [CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
    [OutPutType('System.Collections.Hashtable')]
    param(
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the application')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Password credential keyId to remove')]
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
        $res = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "applications/$id" -Filter "`$select=passwordCredentials"

        if ($null -eq $res -or $res.StatusCode -ge 400)
        {
            Write-Error "Couldn't retrieve passwordCredentials for $id"
            return $res
        }

        $pwdList = $res.PasswordCredentials
        if (($null -ne $pwdList) -and [bool]($pwdList.Where( { $_.KeyId -eq $keyId })))
        {
            $arg = [psobject]@{
                'keyId' = "$keyId"
            }
        }
        else
        {
            Write-Verbose "passwordCredentials credential $keyId not found for applications resource $id"
            return @{
                StatusCode = [System.Net.HttpStatusCode]::NotFound
            }
        }

        if ($null -ne $arg -and $PSCmdlet.ShouldProcess("$Id", 'Delete passwordCredentials'))
        {
            Set-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type applications -Id "$id/removePassword" -Body $arg -Method POST
        }
    }
}
