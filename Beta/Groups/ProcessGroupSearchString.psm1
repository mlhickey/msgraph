function ProcessGroupSearchString
{
    param(
        [string]$SearchString
    )
    $SearchString = [uri]::EscapeDataString($SearchString)
    $Filter = "(startswith(displayName,'$SearchString') or startswith(mail,'$SearchString'))&`$select=displayName,id"
    $list = Get-MSGObject -Debug:$DebugPreference -Verbose:$VerbosePreference -Type groups -Filter $Filter -All
    if ($null -eq $list)
    {
        return $null
    }

    if ($list.GetType().IsSerializable)
    {
        $group = $list.Where( { $_.displayName -eq $SearchString })
        if ($null -eq $group)
        {
            Write-Warning "Found $($list.count) groups that match partial string.  Please select one of these groups and provide the associated objectId"
            $list | Sort-Object -Property displayname
            throw 'Too many groups'
        }
    }
    else
    {
        $group = $list 
    }
    return $group
}
