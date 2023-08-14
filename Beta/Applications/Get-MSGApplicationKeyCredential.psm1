function Get-MSGApplicationKeyCredential
{
    <#
    .SYNOPSIS
    Get credentials assocatied with the specifed id

    .DESCRIPTION
    The Get-MSGApplicationKeyCredential cmdlet gets information about credential objects associated with the specified id.

    .PARAMETER Id
    Specifies the application iD (objectId) of an application in Azure Active Directory

    .PARAMETER Appid
    Specifies the application id of an application in Azure Active Directory

    .EXAMPLE
    Get-MSGApplicationKeyCredential -Id 7f3ea722-a5a6-4252-aada-c204888aacf4

        customKeyIdentifier : vScPTMC2YW7ivE/8pAKLUO5vTtg=
        endDateTime         : 2021-07-18T17:20:31Z
        keyId               : 82b53d1e-0a35-47a2-8598-0c79004ddbec
        startDateTime       : 2019-07-18T17:20:31Z
        type                : AsymmetricX509Cert
        usage               : Verify
        key                 :
        displayName         : CN=Example API
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the application or servicePrincipal.')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'AppId',
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'AppId of the application')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$AppId
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
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'id'
            {
                $res = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "applications/$Id" -Filter "`$select=keyCredentials"
                break
            }
            'appid'
            {
                $res = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'applications' -Filter "appId eq '$AppId'&`$select=keyCredentials"
                break
            }
        }
        if ($res.StatusCode -ge 400)
        {
            return $res
        }
        $res | Select-Object -ExpandProperty keyCredentials
    }
}
