function ResolveIds
{
    param(
        [object]$ObjectList
    )

    $uList = @{}
    foreach ($item in $ObjectList)
    {

        $resolved = [PSCustomObject][Ordered]@{
            PSTypeName        = 'MSPIM.privilegedRoles.assignments.formatted'
            subjectId         = $item.subjectId
            userPrincipalName = $null
            displayName       = $null
            RoleDefinitionId  = $item.RoleDefinitionId
            roleName          = $null
            startDateTime     = $item.startDateTime
            endDateTime       = $item.endDateTime
            isPersistent      = ($item.AssignMentState -eq 'Active' -and $null -eq $item.endDateTime)
        }

        if ($uList.Contains($item.subjectId))
        {
            $user = $uList.Item($item.subjectId)
        }
        else
        {
            $user = Get-MSGObjectById -Ids $item.subjectId -Filter "`$select=displayName,userPrincipalName"
            if ($user.'@odata.type' -eq '#microsoft.graph.servicePrincipal')
            {
                Add-Member -InputObject $user -MemberType NoteProperty -Name userPrincipalName -Value 'ServicePrincipal'
            }
            $uList.Add($item.subjectId, $user)
        }

        if ($null -eq $user.userPrincipalName)
        {
            $resolved.userPrincipalName = 'Unresolveable'
        }
        else
        {
            $resolved.userPrincipalName = $user.userPrincipalName
        }

        $resolved.displayName = $user.displayName
        $resolved.roleName = $roleId2Name.Item($item.RoleDefinitionId).displayName
        $resolved
    }
    $uList.Clear()
}
