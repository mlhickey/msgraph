function New-RoleMapping
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param()
    begin
    {
        $MSGAuthInfo = Get-MSGConfig
        if ($MSGAuthInfo.Initialized -ne $true)
        {
            throw 'You must call the Connect-MSG cmdlet before calling any other cmdlets'
        }

        $global:roleId2Name = @{}
        $global:roleName2Id = @{}
        $roleSettingsMap = @{}
        $roleDefList = @{}
    }

    process
    {
        (Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "privilegedAccess/aadroles/resources/$($MSGAuthInfo.TenantId)/roleDefinitions" -Filter "`$select=id,displayName") | ForEach-Object { $roleDefList.Add($_.Id, $_.displayName) }
        (Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type "privilegedAccess/aadroles/resources/$($MSGAuthInfo.TenantId)/roleSettings" -Filter "`$select=RoleDefinitionId,userMemberSettings") | ForEach-Object { $roleSettingsMap.Add($_.RoleDefinitionId, $_.userMemberSettings) }

        foreach ($role in $roleDefList.GetEnumerator())
        {
            $Expiry = $roleSettingsMap.Item($role.Name).Where( { $_.ruleIdentifier -eq 'ExpirationRule' })
            $Expiry = (ConvertFrom-Json $Expiry.setting)
            $duration = ($Expiry.maximumGrantPeriodInMinutes / 60)
            $o = [PSCustomObject][Ordered]@{
                displayName   = $role.value
                expiryMinutes = $Expiry.maximumGrantPeriodInMinutes
                duration      = "PT$($Duration)H"
            }
            $global:roleId2Name.Add($role.Name, $o)
            $global:roleName2Id.Add($role.value, $role.Name)
        }

        [string[]]$options = @($global:RoleName2Id.Keys | Sort-Object)
        $helpMessage = 'PIM role name: {0}' -f ($options -join ', ' )
        New-DynamicParam -Name RoleName -ValidateSet $options -ParameterSetName 'RoleName' -ValueFromPipelineByPropertyName -HelpMessage $helpMessage
    }
}
