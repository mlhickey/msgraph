function Get-MSGServicePrincipalPasswordCredential
{
    <#
    .SYNOPSIS
    Get credentials assocatied with the specifed service principal

    .DESCRIPTION
    The Get-MSGServicePrincipalPasswordCredential cmdlet gets information about credential objects associated with the specified service principal.

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER AppId
    Specifies the service principal application Id of an service principal in Azure AD.

    .EXAMPLE
    Get-MSGraphServicePrincipalPasswordCredential -Id 0000452e-f046-4197-b292-21d33d8d9bb5

    customKeyIdentifier :
    endDateTime         : 2021-05-11T23:18:00.542Z
    keyId               : 53848e66-57aa-4af2-83c1-100ebfbfc474
    startDateTime       : 2020-05-11T23:18:00.542Z
    secretText          :
    hint                :
    displayName         :
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            ParameterSetName = "Id",
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Id of the application or servicePrincipal.")]
        [Alias("ObjectId")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$Id,

        [Parameter(Mandatory = $false,
            ParameterSetName = "AppId",
            HelpMessage = "AppId of the application")]
        [ValidatePattern("^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$")]
        [string]$AppId
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
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            "id"
            {
                $res = Get-MSGObject -Type "servicePrincipals/$Id" -Filter "`$select=passwordCredentials"
                break
            }
            "appid"
            {
                $res = Get-MSGObject -Type "servicePrincipals" -Filter "appId eq '$AppId'&`$select=passwordCredentials"
                break
            }
        }
        if ($res.StatusCode -ge 400) { return $res }
        $res | Select-Object -ExpandProperty passwordCredentials
    }
}
