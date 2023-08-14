function Get-MSGServicePrincipalKeyCredential
{
    <#
    .SYNOPSIS
    Get credentials assocatied with the specifed service principal

    .DESCRIPTION
    The Get-MSGServicePrincipalKeyCredential cmdlet gets information about credential objects associated with the specified service principal.

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER AppId
    Specifies the service principal application Id of an service principal in Azure AD.

    .EXAMPLE
    Get-MSGraphServicePrincipalKeyCredential -Id 00000a54-128b-4e1f-8c8e-c52f6dde9d84

    customKeyIdentifier : 50BCCCF600B3868EA4D11EEA9BC833A1402204D8
    endDateTime         : 2020-02-08T10:59:00Z
    keyId               : 1fb1d76d-7015-4a78-be23-c682d66708b9
    startDateTime       : 2019-11-10T10:59:00Z
    type                : AsymmetricX509Cert
    usage               : Verify
    key                 :
    displayName         : CN=/subscriptions/c270eec7-82e2-4df5-98eb-e3d1a44f72a2/resourcegroups/FuncRGProdWCUS/provi

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the servicePrincipal')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'AppId',
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
                $res = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "servicePrincipals/$Id" -Filter "`$select=keyCredentials"
                break
            }
            'appid'
            {
                $res = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type 'servicePrincipals' -Filter "appId eq '$AppId'&`$select=keyCredentials"
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
