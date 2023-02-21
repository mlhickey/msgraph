function buildCredList
{
    param(
        [ValidateNotNullOrEmpty()]
        [object[]]$cObjectList
    )

    $list = @()
    if ($null -ne $cObjectList)
    {
        $type = (Get-Member -InputObject $cObjectList[0]).Where( { $_.Name -eq 'type' })
        if ([string]::IsNullOrEmpty($type))
        {
            $type = 'Password'
        }
        else
        {
            $type = $cObjectList[0].Type
        }
        foreach ($cred in $cObjectList)
        {
            $obj = [PSCustomObject][Ordered]@{
                StartDate = (Get-Date $cred.startDateTime).ToString()
                EndDate   = (Get-Date $cred.endDateTime).ToString()
                KeyId     = $cred.KeyId
                Type      = $type
            }
            $list += $obj
        }
    }
    $list
}
