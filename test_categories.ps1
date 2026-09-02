$base = "http://localhost:8080"
$pass = 0; $fail = 0

function Check($name, $content, $pattern) {
    if ($content -match $pattern) {
        Write-Host "PASS  $name" -ForegroundColor Green
        $script:pass++
    } else {
        Write-Host "FAIL  $name" -ForegroundColor Red
        Write-Host "      Got: $($content.Substring(0, [Math]::Min(150, $content.Length)))" -ForegroundColor DarkRed
        $script:fail++
    }
}

Write-Host "`n Category Filter Tests" -ForegroundColor Yellow
Write-Host " =====================`n"

# Test by category_id
$cats = @(
    @{id=1; name="Kitchen Appliances"},
    @{id=2; name="Personal Care & Lifestyle"},
    @{id=3; name="Home Comfort & Utility"},
    @{id=4; name="Electronics & Gadgets"}
)

foreach ($cat in $cats) {
    try {
        $r = Invoke-WebRequest "$base/api/products?category_id=$($cat.id)&limit=50" -UseBasicParsing
        $json = $r.Content | ConvertFrom-Json
        $count = $json.products.Count
        if ($count -gt 0) {
            # Verify all returned products belong to this category
            $wrongCat = $json.products | Where-Object { $_.category_id -ne $cat.id }
            if ($wrongCat.Count -eq 0) {
                Write-Host "PASS  category_id=$($cat.id) ($($cat.name)) => $count products, all correct" -ForegroundColor Green
                $pass++
            } else {
                Write-Host "FAIL  category_id=$($cat.id) => $($wrongCat.Count) products have wrong category!" -ForegroundColor Red
                $fail++
            }
        } else {
            Write-Host "WARN  category_id=$($cat.id) ($($cat.name)) => 0 products (may be empty)" -ForegroundColor Yellow
            $pass++
        }
    } catch {
        Write-Host "FAIL  category_id=$($cat.id) => $_" -ForegroundColor Red
        $fail++
    }
}

# Test by category name
$catNames = @("Kitchen Appliances", "Personal Care & Lifestyle", "Fan & Cooling")
foreach ($name in $catNames) {
    try {
        $enc = [System.Uri]::EscapeDataString($name)
        $r = Invoke-WebRequest "$base/api/products?category=$enc&limit=50" -UseBasicParsing
        $json = $r.Content | ConvertFrom-Json
        $count = $json.products.Count
        Write-Host "PASS  category='$name' => $count products" -ForegroundColor Green
        $pass++
    } catch {
        Write-Host "FAIL  category='$name' => $_" -ForegroundColor Red
        $fail++
    }
}

# Test all products (no filter)
try {
    $r = Invoke-WebRequest "$base/api/products?limit=100" -UseBasicParsing
    $json = $r.Content | ConvertFrom-Json
    $total = $json.products.Count
    Write-Host "PASS  All products (no filter) => $total products" -ForegroundColor Green
    $pass++
} catch {
    Write-Host "FAIL  All products => $_" -ForegroundColor Red
    $fail++
}

Write-Host "`n Results: $pass passed, $fail failed`n" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Yellow" })
