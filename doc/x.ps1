$raw = [System.IO.File]::ReadAllText('C:\Mes Projets\pennylane\doc\accounting.json')
# e_invoicing
$ei = $raw.IndexOf('"e_invoicing"')
Write-Host "=== e_invoicing ==="
Write-Host $raw.Substring($ei, 450)
Write-Host "=== supplier_invoice fields ==="
$si = $raw.IndexOf('"/api/external/v2/supplier_invoices"')
$siChunk = $raw.Substring($si, 18000)
$props = [regex]::Matches($siChunk, '"([a-z][a-z_0-9]+)"\s*:\s*\{"type"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$props
Write-Host "=== customer_invoice fields ==="
$ci = $raw.IndexOf('"/api/external/v2/customer_invoices"')
$ciChunk = $raw.Substring($ci, 18000)
$props2 = [regex]::Matches($ciChunk, '"([a-z][a-z_0-9]+)"\s*:\s*\{"type"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$props2
Write-Host "=== pa_registrations fields ==="
$pa = $raw.IndexOf('"/api/external/v2/pa_registrations"')
$paChunk = $raw.Substring($pa, 8000)
$props3 = [regex]::Matches($paChunk, '"([a-z][a-z_0-9]+)"\s*:\s*\{"type"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$props3
Write-Host "=== me / user profile ==="
$me = $raw.IndexOf('"/api/external/v2/me"')
$meChunk = $raw.Substring($me, 5000)
$props4 = [regex]::Matches($meChunk, '"([a-z][a-z_0-9]+)"\s*:\s*\{"type"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$props4
Write-Host "=== customer fields ==="
$cu = $raw.IndexOf('"/api/external/v2/customers"')
$cuChunk = $raw.Substring($cu, 12000)
$props5 = [regex]::Matches($cuChunk, '"([a-z][a-z_0-9]+)"\s*:\s*\{"type"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$props5
Write-Host "=== supplier fields ==="
$su = $raw.IndexOf('"/api/external/v2/suppliers"')
$suChunk = $raw.Substring($su, 12000)
$props6 = [regex]::Matches($suChunk, '"([a-z][a-z_0-9]+)"\s*:\s*\{"type"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
$props6
