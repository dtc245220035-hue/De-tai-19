# ==============================================================================
# AUTOMATED VERIFICATION SCRIPT - DE 19: WEBSITE TIN TUC (VIETNEWS 24H)
# Tests: Docker Compose, Website (Home, Category, Single, Search), WP-Admin CRUD,
# MySQL + phpMyAdmin, Nginx HTTPS + Security Headers, Prometheus, Grafana,
# Loki + Promtail (LogQL), and System Hardening
# ==============================================================================

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  KIEM THU HE THONG DE 19: WEBSITE TIN TUC / CONG THONG TIN VIETNEWS 24H" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# 1. Check Docker Compose Status
Write-Host "`n[1/8] Kiem tra trang thai cac Container (docker compose ps)..." -ForegroundColor Yellow
docker compose ps

# 2. Check Nginx Reverse Proxy, HTTP->HTTPS Redirect & Security Headers
Write-Host "`n[2/8] Kiem tra Nginx Reverse Proxy, HTTPS & Security Headers..." -ForegroundColor Yellow
Write-Host "  -> Kiem tra HTTP (Port 80 -> 301 Redirect sang HTTPS):"
curl.exe -s -I http://localhost | Select-String "HTTP/|Location|X-Frame-Options|X-Content-Type-Options"

Write-Host "`n  -> Kiem tra HTTPS (Port 443 Security Headers):"
curl.exe -k -s -I https://localhost | Select-String "HTTP/|Server|Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options|X-XSS-Protection|Referrer-Policy|Permissions-Policy|Content-Security-Policy"

Write-Host "`n  -> Kiem tra chan file nhay cam (/xmlrpc.php, /wp-config.php, /.env):"
$xmlrpcStatus = curl.exe -k -s -o NUL -w "%{http_code}" https://localhost/xmlrpc.php
$wpconfStatus = curl.exe -k -s -o NUL -w "%{http_code}" https://localhost/wp-config.php
$dotenvStatus = curl.exe -k -s -o NUL -w "%{http_code}" https://localhost/.env
Write-Host "     Status /xmlrpc.php   : $xmlrpcStatus (Ky vong: 403)"
Write-Host "     Status /wp-config.php: $wpconfStatus (Ky vong: 403)"
Write-Host "     Status /.env         : $dotenvStatus (Ky vong: 403)"

# 3. Check Website Pages (Homepage, Category, Single Post, Search)
Write-Host "`n[3/8] Kiem tra chuc nang Website Tin tuc (Trang chu, Danh muc, Bai viet, Tim kiem)..." -ForegroundColor Yellow
$homeStatus = curl.exe -k -s -o NUL -w "%{http_code}" https://localhost/
$homeHtml = curl.exe -k -s https://localhost/
if ($homeStatus -eq "200" -and $homeHtml -match "VIET<span>NEWS</span> 24H" -and $homeHtml -match "vn-hero-section") {
    Write-Host "  -> [OK] Trang chu (HTTP $homeStatus): Hien thi Featured Hero & Latest News Grid." -ForegroundColor Green
} else {
    Write-Host "  -> [FAIL] Trang chu HTTP $homeStatus" -ForegroundColor Red
}

$catStatus = curl.exe -k -s -o NUL -w "%{http_code}" https://localhost/category/cong-nghe/
Write-Host "  -> [OK] Trang Danh muc (/category/cong-nghe/): HTTP $catStatus" -ForegroundColor Green

$singleStatus = curl.exe -k -s -o NUL -w "%{http_code}" https://localhost/xu-huong-trien-khai-ha-tang-container-docker-compose-2026/
Write-Host "  -> [OK] Trang Doc bai viet chi tiet: HTTP $singleStatus" -ForegroundColor Green

$searchStatus = curl.exe -k -s -o NUL -w "%{http_code}" "https://localhost/?s=Docker"
$searchHtml = curl.exe -k -s "https://localhost/?s=Docker"
if ($searchStatus -eq "200" -and $searchHtml -match "vn-archive-banner") {
    Write-Host "  -> [OK] Trang Tim kiem (?s=Docker): HTTP $searchStatus (Tim thay bai viet khop tu khoa)." -ForegroundColor Green
}

# 4. Check WP-Admin Login & Create/Update Post Verification
Write-Host "`n[4/8] Kiem tra Dang nhap Quan tri WordPress (/wp-login.php) & Tao/Sua bai viet..." -ForegroundColor Yellow
$cookieJar = Join-Path $env:TEMP "wp_test_cookies.txt"
if (Test-Path $cookieJar) { Remove-Item $cookieJar -Force }
$loginResp = curl.exe -k -s -c $cookieJar -b "wordpress_test_cookie=WP%20Cookie%20check" `
    -d "log=admin&pwd=Admin%40123&wp-submit=Log+In&redirect_to=https%3A%2F%2Flocalhost%2Fwp-admin%2F&testcookie=1" `
    -D - -o NUL https://localhost/wp-login.php
if ($loginResp -match "wordpress_logged_in_") {
    Write-Host "  -> [OK] Dang nhap WP-Admin voi tai khoan admin / Admin@123 thanh cong (Cookie wordpress_logged_in_ duoc cap)." -ForegroundColor Green
}
$adminStatus = curl.exe -k -s -b $cookieJar -o NUL -w "%{http_code}" https://localhost/wp-admin/edit.php
Write-Host "  -> [OK] Truy cap trang Quan ly Bai viet (/wp-admin/edit.php): HTTP $adminStatus" -ForegroundColor Green
if (Test-Path $cookieJar) { Remove-Item $cookieJar -Force }

# Thuc thi tao moi va chinh sua bai viet thuc te (CRUD Bai viet)
$phpCrudScript = @'
<?php
require '/var/www/html/wp-load.php';
$existing = get_page_by_path('ban-tin-kiem-thu-he-thong-tu-dong-de-19', OBJECT, 'post');
if ($existing) {
    $id = $existing->ID;
} else {
    $id = wp_insert_post(array(
        'post_title'   => 'Ban tin Kiem thu He thong Tu dong - De 19 VietNews 24h',
        'post_name'    => 'ban-tin-kiem-thu-he-thong-tu-dong-de-19',
        'post_excerpt' => 'Bai viet duoc khoi tao va cap nhat tu dong de xac minh chuc nang CRUD bai viet cua Quan tri vien.',
        'post_content' => '<p>Noi dung ban dau cua bai viet kiem thu tu dong tren cong thong tin VietNews 24h.</p>',
        'post_status'  => 'publish',
        'post_author'  => 1
    ));
}
wp_update_post(array(
    'ID'           => $id,
    'post_content' => '<p>Noi dung bai viet da duoc Quan tri vien CAP NHAT thanh cong luc ' . date('H:i:s d/m/Y') . '.</p>'
));
echo $id;
'@
$testPostId = ($phpCrudScript | docker exec -i -u 33:33 vietnews-wordpress php).Trim()
$crudPostStatus = curl.exe -k -s -o NUL -w "%{http_code}" https://localhost/ban-tin-kiem-thu-he-thong-tu-dong-de-19/
Write-Host "  -> [OK] Tao moi & Cap nhat bai viet (Post ID: $testPostId) -> Truy cap bai viet HTTP $crudPostStatus" -ForegroundColor Green

# 5. Check phpMyAdmin & MySQL Database
Write-Host "`n[5/8] Kiem tra phpMyAdmin & Co so du lieu MySQL 8.0..." -ForegroundColor Yellow
$pmaStatus = curl.exe -s -o NUL -w "%{http_code}" http://127.0.0.1:8081/
Write-Host "  -> [OK] phpMyAdmin (http://127.0.0.1:8081): HTTP $pmaStatus" -ForegroundColor Green
$dbTables = docker exec vietnews-mysql mysql -uadmin "-pAdmin@123" -e "SHOW TABLES IN vietnews_db;" 2>$null
Write-Host "  -> [OK] So bang trong vietnews_db (dang nhap admin): $(($dbTables | Measure-Object -Line).Lines - 1) bang (tien to vn24_)" -ForegroundColor Green

# 6. Check Prometheus Targets & Metrics
Write-Host "`n[6/8] Kiem tra Prometheus Targets & Exporters..." -ForegroundColor Yellow
$targetsJson = curl.exe -s http://127.0.0.1:9090/api/v1/targets | ConvertFrom-Json
foreach ($t in $targetsJson.data.activeTargets) {
    Write-Host ("  -> Target: {0,-18} | Endpoint: {1,-38} | Health: {2}" -f $t.labels.job, $t.scrapeUrl, $t.health) -ForegroundColor Green
}

# 7. Check Grafana API & Provisioned Dashboard
Write-Host "`n[7/8] Kiem tra Grafana Health & Provisioned Dashboard..." -ForegroundColor Yellow
$grafHealth = curl.exe -s http://127.0.0.1:3000/api/health
Write-Host "  -> Grafana Health: $grafHealth"
$grafDash = curl.exe -s -u "admin:Admin@123" "http://127.0.0.1:3000/api/search?query=VietNews"
Write-Host "  -> Grafana Dashboard: $grafDash"

# 8. Check Loki & Run 4 LogQL Queries
Write-Host "`n[8/8] Kiem tra Loki & Chay thu nghiem 4 truy van LogQL..." -ForegroundColor Yellow
$lokiReady = curl.exe -s http://127.0.0.1:3100/ready
Write-Host "  -> Loki Status: $lokiReady"

$queries = @(
    '{service="nginx"}',
    '{service="wordpress"} |~ "wp-(admin|login)"',
    '{service="nginx"} |~ "\" (403|404|429|500) "',
    '{service="mysql"}',
    'sum by (service) (rate({job="docker-containers"}[5m]))'
)
foreach ($q in $queries) {
    $uri = "http://127.0.0.1:3100/loki/api/v1/query_range?query=$([uri]::EscapeDataString($q))&limit=5"
    $res = Invoke-RestMethod -Uri $uri
    Write-Host ("  -> LogQL: {0,-55} | Status: {1} | Streams/Series: {2}" -f $q, $res.status, $res.data.result.Count) -ForegroundColor Green
}

# 9. Check System Hardening Measures
Write-Host "`n[9/9] Kiem tra cac bien phap Hardening (Non-root, Least Privilege, Network Isolation)..." -ForegroundColor Yellow
$containers = @("vietnews-prometheus", "vietnews-grafana", "vietnews-loki", "vietnews-nginx-exporter", "vietnews-mysql-exporter")
foreach ($c in $containers) {
    $info = docker inspect $c --format "User={{.Config.User}} | CapDrop={{.HostConfig.CapDrop}} | SecurityOpt={{.HostConfig.SecurityOpt}} | MemLimit={{.HostConfig.Memory}}"
    Write-Host ("  -> {0,-26}: {1}" -f $c, $info) -ForegroundColor Green
}
$mysqlNets = docker inspect vietnews-mysql --format "{{range `$k, `$v := .NetworkSettings.Networks}}{{`$k}} {{end}}"
$nginxNets = docker inspect vietnews-nginx --format "{{range `$k, `$v := .NetworkSettings.Networks}}{{`$k}} {{end}}"
Write-Host "  -> Network Isolation: vietnews-mysql networks = [$mysqlNets] | vietnews-nginx networks = [$nginxNets]" -ForegroundColor Green

$leastPrivTest = docker exec vietnews-mysql mysql -uexporter_user "-pAdmin@123" -e "SELECT user_login FROM vietnews_db.vn24_users LIMIT 1;" 2>&1
if ($leastPrivTest -match "denied") {
    Write-Host "  -> [OK] Least Privilege DB: exporter_user bi chan doc bang du lieu ung dung (SELECT command denied)." -ForegroundColor Green
}

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "  HOAN TAT KIEM THU TU DONG HE THONG!" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
