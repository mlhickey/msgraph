function New-SigninRecord
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param(
        [object]$record
    )

    $reportBody = [PSCustomObject][Ordered]@{
        PSTypeName                       = "MSGraph.SigninRecord"
        Date                             = $record.createdDateTime
        UserDisplayName                  = $record.UserDisplayName
        userPrincipalName                = $record.userPrincipalName
        UserId                           = $record.UserId
        appId                            = $record.appId
        AppDisplayName                   = $record.AppDisplayName
        Status                           = $null
        ConditionalAccessStatus          = $record.ConditionalAccessStatus
        IpAddress                        = $record.IpAddress
        ClientAppUsed                    = $record.IpAddress
        IsInteractive                    = $record.IsInteractive
        TokenIssuerName                  = $record.TokenIssuerName
        TokenIssuerType                  = $record.TokenIssuerType
        resourceDisplayName              = $record.resourceDisplayName
        resourceId                       = $record.resourceId
        CorrelationId                    = $record.CorrelationId
        DeviceDetail                     = $null
        Location                         = $null
        MFADetail                        = $null
        AppliedConditionalAccessPolicies = $null
    }
    #region Status
    if ($null -ne $record.Status)
    {
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name errorCode -Value $record.Status.ErrorCode
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name failureReason -Value $record.Status.failureReason
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name additionalDetails -Value $record.Status.additionalDetails
    }
    #endregion Status
    #region DeviceDetails
    if ($null -ne $record.DeviceDetail)
    {
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name deviceId -Value $record.DeviceDetail.deviceId
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name displayName -Value $record.DeviceDetail.displayName
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name operatingSystem -Value $record.DeviceDetail.operatingSystem
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name browser -Value $record.DeviceDetail.browser
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name isCompliant -Value $record.DeviceDetail.isCompliant
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name isManaged -Value $record.DeviceDetail.isManaged
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name trustType -Value $record.DeviceDetail.trustType
    }
    #region DeviceDetails
    #region Location
    if ($null -ne $record.Location)
    {
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name city -Value $record.Location.city
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name state -Value $record.Location.state
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name countryOrRegion -Value $record.Location.countryOrRegion
        if ($null -ne $record.Location.geoCoordinates)
        {
            Add-Member -InputObject $reportBody -MemberType NoteProperty -Name altitude -Value $record.Location.geoCoordinates.altitude
            Add-Member -InputObject $reportBody -MemberType NoteProperty -Name latitude -Value $record.Location.geoCoordinates.latitude
            Add-Member -InputObject $reportBody -MemberType NoteProperty -Name longitude -Value $record.Location.geoCoordinates.longitude
        }
    }
    #endregion Location
    #region CAPolicies
    $pCount = 0
    foreach ($p in $record.AppliedConditionalAccessPolicies)
    {
        $pCount++
        $pLabel = "policy$pCount"
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name "$($pLabel)Id" -Value $p.Id
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name "$($pLabel)DisplayName" -Value $p.displayName
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name "$($pLabel)Result" -Value $p.Result
    }
    #endregion #region CAPolicies
    $reportBody
}
