$base = "http://localhost:8080"
$pass = 0; $fail = 0

function Check($name, $content, $pattern) {
    if ($content -match $pattern) {
        Write-Host "PASS  $name" -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host "FAIL  $name" -ForegroundColor Red
        Write-Host "      Got: $($content.Substring(0, [Math]::Min(120, $content.Length)))" -ForegroundColor DarkRed
        $script:fail++
    }
}

Write-Host "`n ElectroZoneBD Backend Test Suite" -ForegroundColor Yellow
Write-Host " ==================================`n"

# 1. Health
try {
    $r = Invoke-WebRequest "$base/api/health" -UseBasicParsing
    Check "Health check" $r.Content "ok"
} catch { Write-Host "FAIL  Health check => $_" -ForegroundColor Red; $fail++ }

# 2. GET site_settings
try {
    $r = Invoke-WebRequest "$base/api/site_settings?key=support_whatsapp_number" -UseBasicParsing
    Check "GET site_settings" $r.Content "setting_value"
} catch { Write-Host "FAIL  GET site_settings => $_" -ForegroundColor Red; $fail++ }

# 3. POST site_settings (save WhatsApp number)
try {
    $body = '{"setting_key":"support_whatsapp_number","setting_value":"8801999888777"}'
    $r = Invoke-WebRequest "$base/api/site_settings" -Method POST -Body $body -ContentType "application/json" -UseBasicParsing
    Check "POST site_settings (save)" $r.Content "success"
} catch { Write-Host "FAIL  POST site_settings => $_" -ForegroundColor Red; $fail++ }

# 4. Confirm saved value
try {
    $r = Invoke-WebRequest "$base/api/site_settings?key=support_whatsapp_number" -UseBasicParsing
    Check "GET site_settings (confirm)" $r.Content "8801999888777"
} catch { Write-Host "FAIL  GET confirm => $_" -ForegroundColor Red; $fail++ }

# 5. Admin login
$token = $null
try {
    $body = '{"email":"testadmin@local.com","password":"Admin@1234"}'
    $r = Invoke-WebRequest "$base/api/auth/login" -Method POST -Body $body -ContentType "application/json" -UseBasicParsing
    Check "Admin login" $r.Content "token"
    $token = ($r.Content | ConvertFrom-Json).token
} catch { Write-Host "FAIL  Admin login => $_" -ForegroundColor Red; $fail++ }

# 6. Admin orders
try {
    $headers = @{ "Authorization" = "Bearer $token" }
    $r = Invoke-WebRequest "$base/api/orders?admin=true" -Headers $headers -UseBasicParsing
    Check "Admin orders GET" $r.Content "order_id"
} catch { Write-Host "FAIL  Admin orders => $_" -ForegroundColor Red; $fail++ }

# 7. Products
try {
    $r = Invoke-WebRequest "$base/api/products" -UseBasicParsing
    Check "Products API" $r.Content "product"
} catch { Write-Host "FAIL  Products => $_" -ForegroundColor Red; $fail++ }

# 8. Categories
try {
    $r = Invoke-WebRequest "$base/api/categories" -UseBasicParsing
    Check "Categories API" $r.Content "category"
} catch { Write-Host "FAIL  Categories => $_" -ForegroundColor Red; $fail++ }

Write-Host "`n Results: $pass passed, $fail failed`n" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Yellow" })
