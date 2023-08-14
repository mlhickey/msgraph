function Get-MSGServicePrincipalSingleSignOnCredential
{
    <#
    .SYNOPSIS
    Returns a list of single sign-on credentials using a password for a user or group

    .DESCRIPTION
    The Get-MSGServicePrincipalSingleSignOnCredential cmdlet Returns a list of sign-on credentials for the specified service principal id.

    .PARAMETER Id
    Specifies the Id (ObjectId) of an service principal in Azure AD.

    .PARAMETER Properties
    Specifies the list of properties to return.  Property names are case-sensitive

    .LINK
     https://docs.microsoft.com/en-us/graph/api/serviceprincipal-getpasswordsinglesignoncredentials?view=graph-rest-beta&tabs=http
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Id of the servicePrincipal')]
        [Alias('ObjectId')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$Id
    )

    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            {
                throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
            }
        }
    }

    process
    {
        Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "servicePrincipals/$id/getPasswordSingleSignOnCredentials"
    }
}

