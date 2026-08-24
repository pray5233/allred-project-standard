param(
    [string]$InputPath = (Join-Path $PSScriptRoot 'orders.csv'),
    [string]$OutputPath = (Join-Path $PSScriptRoot 'summary.csv')
)

$orders = Import-Csv -LiteralPath $InputPath
$summary = [pscustomobject]@{
    TotalCount = @($orders).Count
    CompletedCount = @($orders | Where-Object { $_.Status -eq '完成' }).Count
}

$summary | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8
