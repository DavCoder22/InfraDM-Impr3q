# Test AWS Permissions Script
Write-Host "Testing AWS CLI Configuration..."
Write-Host "--------------------------------"

# Test AWS CLI configuration
try {
    $caller = aws sts get-caller-identity 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ AWS CLI is properly configured" -ForegroundColor Green
        $caller | ConvertFrom-Json | Format-List
    } else {
        Write-Host "❌ AWS CLI configuration error:" -ForegroundColor Red
        Write-Host $caller -ForegroundColor Red
        exit 1
    }

    # Test basic EC2 permissions
    Write-Host "`nTesting EC2 Permissions..."
    Write-Host "---------------------------"
    $regions = aws ec2 describe-regions --query "Regions[].RegionName" --output text 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ EC2 DescribeRegions permission granted" -ForegroundColor Green
        Write-Host "Available regions: $regions"
    } else {
        Write-Host "❌ No EC2 DescribeRegions permission:" -ForegroundColor Yellow
        Write-Host $regions -ForegroundColor Yellow
    }

    # Test S3 permissions
    Write-Host "`nTesting S3 Permissions..."
    Write-Host "------------------------"
    $buckets = aws s3api list-buckets --query "Buckets[].Name" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ S3 ListBuckets permission granted" -ForegroundColor Green
        Write-Host "Buckets: $buckets"
    } else {
        Write-Host "❌ No S3 ListBuckets permission:" -ForegroundColor Yellow
        Write-Host $buckets -ForegroundColor Yellow
    }

} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}
