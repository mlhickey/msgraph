function Get-MSGTenantInfo
{
    param(
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Id',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Tenant  Id')]
        [ValidatePattern('^([0-9a-fA-F]){8}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){4}-([0-9a-fA-F]){12}$')]
        [string]$TenantId,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Domain',
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Tenant domain name')]
        [ValidatePattern('^(?!:\/\/)(?=.{1,255}$)((.{1,63}\.){1,127}(?![0-9]*$)[a-z0-9-]+\.?)$')]
        [string]$DomainName
    )

    Begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }
    }

    Process
    {
        switch ($PsCmdlet.ParameterSetName.ToLower())
        {
            'id'
            {
                $typeString = "findTenantInformationByTenantId(tenantId='$TenantId')"
                break
            }
            'domain'
            {
                $typeString = "findTenantInformationByDomainName(domainName='$DomainName')"
                break
            }
        }

        Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "tenantRelationships/$typeString"
    }
}
