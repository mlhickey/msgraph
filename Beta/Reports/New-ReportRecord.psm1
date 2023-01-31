function New-ReportRecord
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param(
        [object]$record
    )

    $reportBody = [PSCustomObject][Ordered]@{
        PSTypeName                = "MSGraph.ReportRecord"
        Date                      = $record.activityDateTime
        CorrelationId             = $record.CorrelationId
        Service                   = $record.loggedByService
        Category                  = $record.Category
        Activity                  = $record.activityDisplayName
        Result                    = $record.Result
        ResultReason              = $record.ResultReason
        ActorType                 = $null
        ActorDisplayName          = $null
        ActorObjectId             = $null
        ActorUserPrincipalName    = $null
        ActorServicePrincipalId   = $null
        ActorServicePrincipalName = $null
    }
    #region ActorInformatio
    if ($null -ne $record.initiatedBy.app)
    {
        $reportBody.ActorObjectId = $record.initiatedBy.app.Id
        $reportBody.ActorDisplayName = $record.initiatedBy.app.displayName
        $reportBody.ActorServicePrincipalId = $record.initiatedBy.app.servicePrincipalId
        $reportBody.ActorServicePrincipalName = $record.initiatedBy.app.servicePrincipalName
    }
    elseif ($null -ne $record.initiatedBy.user)
    {
        $reportBody.ActorObjectId = $record.initiatedBy.user.Id
        $reportBody.ActorDisplayName = $record.initiatedBy.user.displayName
        $reportBody.ActorUserPrincipalName = $record.initiatedBy.user.userPrincipalName
    }
    #endregion ActorInformatio
    #region targetResources
    $pCount = 0
    foreach ($t in $record.targetResources)
    {
        $pCount++

        $tLabel = "Target$pCount"
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name "$($tLabel)Type" -Value $t.Type
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name "$($tLabel)DisplayName" -Value $t.displayName
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name "$($tLabel)ObjectId" -Value $t.Id
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name "$($tLabel)UserPrincipalName" -Value $t.userPrincipalName
        #region modifiedProperties
        $mCount = 0
        foreach ($m in $t.modifiedProperties)
        {
            $mCount++
            $mLabel = $tLabel + "ModifiedProperty$($mCount)"
            Add-Member -InputObject $reportBody -MemberType NoteProperty -Name "$($mLabel)Name" -Value $m.displayName
            Add-Member -InputObject $reportBody -MemberType NoteProperty -Name "$($mLabel)OldValue" -Value $m.oldValue
            Add-Member -InputObject $reportBody -MemberType NoteProperty -Name "$($mLabel)Newalue" -Value $m.newValue
        }
        #endregion modifiedProperties
    }
    #endregion targetResources
    #region additionalDetails
    $aCount = 0
    foreach ($a in $record.additionalDetails)
    {
        $aCount++
        $aLabel = "AdditionalDetail$($aCount)"
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name "$($aLabel)Key" -Value $a.Key
        Add-Member -InputObject $reportBody -MemberType NoteProperty -Name "$($aLabel)Value" -Value $a.value
    }
    #endregion additionalDetails
    $reportBody
}
