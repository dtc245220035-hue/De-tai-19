#!/bin/sh
set -e

echo "=================================================================="
echo "[VietNews 24h Setup] Bat dau khoi tao Cổng Thông Tin Điện Tử Đề 19"
echo "=================================================================="

cd /var/www/html

# 1. Đợi WordPress container giải nén mã nguồn vào /var/www/html
echo "[1/6] Đang đợi mã nguồn WordPress tại /var/www/html..."
RETRY=0
while [ ! -f /var/www/html/wp-includes/version.php ]; do
    RETRY=$((RETRY + 1))
    if [ "$RETRY" -gt 60 ]; then
        echo "Lỗi: Quá thời gian chờ mã nguồn WordPress!"
        exit 1
    fi
    sleep 2
done

# 2. Đợi kết nối MySQL sẵn sàng
echo "[2/6] Đang kiểm tra kết nối tới MySQL Database..."
RETRY=0
until wp db check --allow-root >/dev/null 2>&1; do
    RETRY=$((RETRY + 1))
    if [ "$RETRY" -gt 60 ]; then
        echo "Lỗi: Không thể kết nối MySQL sau 120 giây!"
        exit 1
    fi
    echo "  -> Đợi MySQL khởi động (lần thử $RETRY)..."
    sleep 2
done
echo "  -> Kết nối MySQL thành công!"

# 3. Cài đặt WordPress nếu chưa được cài
if ! wp core is-installed --allow-root >/dev/null 2>&1; then
    echo "[3/6] Tiến hành cài đặt WordPress tự động..."
    wp core install \
        --url="${WP_SITE_URL:-https://localhost}" \
        --title="${WP_SITE_TITLE:-VietNews 24h - Cổng Thông Tin Điện Tử Tổng Hợp}" \
        --admin_user="${WP_ADMIN_USER:-admin_vietnews}" \
        --admin_password="${WP_ADMIN_PASSWORD:-VnNews#Admin$2026!Portal66}" \
        --admin_email="${WP_ADMIN_EMAIL:-banbientap@vietnews24h.local}" \
        --skip-email \
        --allow-root

    echo "  -> Đã cài đặt WordPress hoàn tất!"
else
    echo "[3/6] WordPress đã được cài đặt từ trước."
fi

# 4. Cấu hình thông số hệ thống & kích hoạt giao diện VietNews 24h Portal
echo "[4/6] Cấu hình múi giờ Việt Nam, Permalink và kích hoạt Theme VietNews 24h..."
wp option update blogname "${WP_SITE_TITLE:-VietNews 24h - Cổng Thông Tin Điện Tử Tổng Hợp}" --allow-root
wp option update blogdescription "Cổng thông tin điện tử tin tức Thời sự, Công nghệ, Kinh tế, An ninh mạng cập nhật 24/7" --allow-root
wp option update timezone_string "Asia/Ho_Chi_Minh" --allow-root
wp option update date_format "d/m/Y" --allow-root
wp option update time_format "H:i" --allow-root
wp option update posts_per_page 10 --allow-root
wp rewrite structure '/%postname%/' --hard --allow-root
wp rewrite flush --hard --allow-root

# Kích hoạt giao diện tin tức tiếng Việt chuyên biệt
wp theme activate vietnews-portal --allow-root

# Tạo thêm tài khoản Biên tập viên (Editor) phục vụ phân quyền quản trị
if ! wp user get "${WP_EDITOR_USER:-bientapvien}" --allow-root >/dev/null 2>&1; then
    wp user create "${WP_EDITOR_USER:-bientapvien}" "${WP_EDITOR_EMAIL:-bientap@vietnews24h.local}" \
        --role=editor \
        --user_pass="${WP_EDITOR_PASSWORD:-VnNews#Editor$2026!News55}" \
        --display_name="Biên Tập Viên Thời Sự" \
        --allow-root
fi

# 5. Tạo các Danh mục Tin tức chuẩn cho Đề 19
echo "[5/6] Khởi tạo hệ thống Danh mục Tin tức..."

create_or_get_cat() {
    SLUG="$1"
    NAME="$2"
    DESC="$3"
    EXISTING_ID=$(wp term list category --slug="$SLUG" --field=term_id --allow-root | head -n 1)
    if [ -n "$EXISTING_ID" ]; then
        echo "$EXISTING_ID"
    else
        wp term create category "$NAME" --slug="$SLUG" --description="$DESC" --porcelain --allow-root
    fi
}

CAT_THOISU=$(create_or_get_cat "thoi-su" "Thời sự" "Tin tức thời sự trong nước, chuyển đổi số quốc gia và các sự kiện nổi bật hàng ngày.")
CAT_CONGNGHE=$(create_or_get_cat "cong-nghe" "Công nghệ & AI" "Xu hướng Trí tuệ nhân tạo, điện toán đám mây, công nghệ bán dẫn và đổi mới sáng tạo.")
CAT_KINHTE=$(create_or_get_cat "kinh-te" "Kinh tế - Tài chính" "Toàn cảnh kinh tế vĩ mô, tài chính ngân hàng, thương mại điện tử và doanh nghiệp số.")
CAT_ANNINHMANG=$(create_or_get_cat "an-ninh-mang" "An ninh mạng & Hệ thống" "Kiến trúc hạ tầng Docker, DevSecOps, giám sát Prometheus/Grafana và bảo mật hệ thống.")
CAT_GIAODUC=$(create_or_get_cat "giao-duc" "Giáo dục" "Đào tạo nhân lực công nghệ cao, đại học số và chuyển đổi phương pháp giảng dạy hiện đại.")
CAT_DOISONG=$(create_or_get_cat "doi-song" "Đời sống" "Nhịp sống đô thị thông minh, văn hóa số và tiện ích công nghệ phục vụ người dân.")

wp option update default_category "$CAT_THOISU" --allow-root

# Xóa bài viết mặc định "Hello world!" nếu còn tồn tại
if wp post get 1 --allow-root >/dev/null 2>&1; then
    FIRST_SLUG=$(wp post get 1 --field=post_name --allow-root 2>/dev/null || true)
    if [ "$FIRST_SLUG" = "hello-world" ]; then
        wp post delete 1 --force --allow-root >/dev/null 2>&1 || true
    fi
fi

# 6. Khởi tạo dữ liệu mẫu bài viết tin tức tiếng Việt (nếu số bài viết < 5)
POST_COUNT=$(wp post list --post_type=post --post_status=publish --format=count --allow-root)
if [ "$POST_COUNT" -lt 5 ]; then
    echo "[6/6] Đang khởi tạo 10 bài viết mẫu Tiếng Việt chất lượng cao cho Cổng thông tin..."

    # Bài 1 (Nổi bật 1 - An ninh mạng & Hệ thống)
    P1=$(wp post create \
        --post_type=post \
        --post_status=publish \
        --post_title="Xu hướng triển khai hạ tầng Microservices và Container hóa với Docker Compose năm 2026" \
        --post_name="xu-huong-trien-khai-ha-tang-container-docker-compose-2026" \
        --post_excerpt="Việc chuẩn hóa môi trường triển khai ứng dụng bằng Docker Compose kết hợp Nginx Reverse Proxy, Prometheus, Grafana và Loki đang trở thành tiêu chuẩn vàng trong quản trị hệ thống hiện đại." \
        --post_category="$CAT_ANNINHMANG,$CAT_CONGNGHE" \
        --tags_input="Docker,DevSecOps,Nginx,Prometheus,Grafana,Loki" \
        --post_content="<p>Trong kỷ nguyên chuyển đổi số mạnh mẽ, các tổ chức và doanh nghiệp công nghệ ngày càng ưu tiên sử dụng kiến trúc đóng gói bằng <strong>Container (Docker)</strong> để thay thế phương thức triển khai máy chủ vật lý hoặc máy ảo truyền thống tốn kém tài nguyên.</p><h2>1. Lợi ích vượt trội của kiến trúc đa Container</h2><p>Khi triển khai một cổng thông tin điện tử có lượng truy cập lớn, việc tách biệt từng thành phần gồm <em>Nginx Reverse Proxy</em>, <em>Ứng dụng Web (WordPress)</em>, <em>Cơ sở dữ liệu (MySQL)</em>, cùng hệ thống giám sát <em>Prometheus + Grafana</em> và thu thập nhật ký tập trung <em>Loki + Promtail</em> giúp hệ thống đạt được tính mô-đun hóa cao, dễ dàng mở rộng và khắc phục sự cố nhanh chóng.</p><blockquote>Hệ thống giám sát chủ động (Observability) kết hợp giữa Metrics và Logs giúp đội ngũ quản trị hệ thống phát hiện sớm 95% sự cố trước khi ảnh hưởng đến người dùng cuối.</blockquote><h2>2. Bảo mật đa lớp (Defense in Depth)</h2><ul><li><strong>Cô lập mạng (Network Isolation):</strong> Tách biệt hoàn toàn mạng Frontend và mạng Backend chứa cơ sở dữ liệu.</li><li><strong>Nguyên tắc đặc quyền tối thiểu (Least Privilege):</strong> Vận hành container với tài khoản non-root và giới hạn Linux Capabilities.</li><li><strong>Bảo vệ đường truyền:</strong> Triển khai mã hóa TLS/HTTPS kèm theo các HTTP Security Headers chống tấn công XSS, Clickjacking.</li></ul><p>Sự kết hợp đồng bộ giữa tự động hóa triển khai và quản trị an toàn đang mở ra chuẩn mực mới cho các kỹ sư hệ thống tại Việt Nam.</p>" \
        --porcelain --allow-root)
    wp post meta update "$P1" _vietnews_views_count 2845 --allow-root

    # Bài 2 (Nổi bật 2 - Thời sự)
    P2=$(wp post create \
        --post_type=post \
        --post_status=publish \
        --post_title="Chuyển đổi số quốc gia bước vào giai đoạn tăng tốc: Hạ tầng dữ liệu số là trọng tâm" \
        --post_name="chuyen-doi-so-quoc-gia-buoc-vao-giai-doan-tang-toc" \
        --post_excerpt="Các bộ, ngành và địa phương đang đẩy mạnh kết nối, chia sẻ dữ liệu tập trung nhằm cung cấp dịch vụ công trực tuyến toàn trình, lấy người dân và doanh nghiệp làm trung tâm." \
        --post_category="$CAT_THOISU" \
        --tags_input="Chuyển đổi số,Chính phủ số,Dữ liệu lớn,Thời sự" \
        --post_content="<p>Theo báo cáo mới nhất về tiến độ phát triển Chính phủ số và Kinh tế số, hạ tầng trung tâm dữ liệu và các cổng thông tin điện tử tích hợp đã ghi nhận bước nhảy vọt về cả quy mô lẫn chất lượng phục vụ.</p><h2>Đẩy mạnh liên thông dữ liệu an toàn</h2><p>Việc đồng bộ hóa cơ sở dữ liệu quốc gia giúp rút ngắn tới 60% thời gian xử lý thủ tục hành chính. Các hệ thống cổng thông tin thế hệ mới đều bắt buộc áp dụng tiêu chuẩn mã hóa đầu cuối và hệ thống giám sát an toàn thông tin liên tục 24/7.</p><h2>Hướng tới đô thị thông minh bền vững</h2><p>Tại các thành phố lớn như Hà Nội, TP. Hồ Chí Minh và Đà Nẵng, người dân đã có thể tra cứu thông tin quy hoạch, giao thông, y tế và giáo dục ngay trên một nền tảng hợp nhất với tốc độ phản hồi dưới 1 giây.</p>" \
        --porcelain --allow-root)
    wp post meta update "$P2" _vietnews_views_count 1960 --allow-root

    # Bài 3 (Nổi bật 3 - Công nghệ & AI)
    P3=$(wp post create \
        --post_type=post \
        --post_status=publish \
        --post_title="Trí tuệ nhân tạo tạo sinh (Generative AI) thay đổi cách vận hành tòa soạn báo điện tử hiện đại" \
        --post_name="tri-tue-nhan-tao-thay-doi-cach-van-hanh-toa-soan-bao-dien-tu" \
        --post_excerpt="Từ khâu tổng hợp dữ liệu, gợi ý tiêu đề chuẩn SEO cho tới cá nhân hóa luồng tin tức theo sở thích độc giả, AI đang trở thành trợ lý đắc lực của các phóng viên và biên tập viên." \
        --post_category="$CAT_CONGNGHE" \
        --tags_input="AI,Báo chí số,Công nghệ,Tòa soạn hội tụ" \
        --post_content="<p>Sự bùng nổ của các mô hình ngôn ngữ lớn (LLM) đã mang lại làn gió mới cho ngành truyền thông và báo chí trực tuyến. Các cổng thông tin điện tử hiện đại không chỉ dừng lại ở việc đăng tải tin tức một chiều mà còn tối ưu hóa trải nghiệm đọc theo thời gian thực.</p><h2>Tự động hóa quy trình biên tập</h2><p>Các công cụ AI hỗ trợ kiểm tra chính tả tiếng Việt, tóm tắt văn bản dài thành các điểm chính (Key Takeaways) và phân loại chuyên mục tự động, giúp đội ngũ biên tập tiết kiệm hàng giờ làm việc mỗi ngày.</p><blockquote>AI không thay thế nhà báo, nhưng những nhà báo biết ứng dụng AI và dữ liệu số sẽ dẫn dắt tương lai của truyền thông hiện đại.</blockquote>" \
        --porcelain --allow-root)
    wp post meta update "$P3" _vietnews_views_count 1742 --allow-root

    # Bài 4 (Nổi bật 4 - Kinh tế - Tài chính)
    P4=$(wp post create \
        --post_type=post \
        --post_status=publish \
        --post_title="Kinh tế số Việt Nam duy trì đà tăng trưởng ấn tượng nhờ thương mại điện tử và thanh toán không tiền mặt" \
        --post_name="kinh-te-so-viet-nam-duy-tri-da-tang-truong-an-tuong" \
        --post_excerpt="Tỷ trọng kinh tế số trong GDP tiếp tục gia tăng mạnh mẽ nhờ sự phổ cập của thanh toán QR, ngân hàng số và hệ sinh thái logistics thông minh trên toàn quốc." \
        --post_category="$CAT_KINHTE" \
        --tags_input="Kinh tế số,Tài chính,Thương mại điện tử,Fintech" \
        --post_content="<p>Báo cáo toàn cảnh thị trường tài chính - công nghệ cho thấy hơn 85% người trưởng thành tại các đô thị lớn đã sử dụng phương thức thanh toán điện tử trong chi tiêu hàng ngày.</p><h2>Sự trỗi dậy của doanh nghiệp công nghệ nội địa</h2><p>Không chỉ dừng lại ở tiêu dùng nội địa, các giải pháp phần mềm quản trị doanh nghiệp (ERP, SaaS) và dịch vụ đám mây do kỹ sư Việt Nam phát triển đang vươn ra thị trường khu vực Đông Nam Á.</p>" \
        --porcelain --allow-root)
    wp post meta update "$P4" _vietnews_views_count 1530 --allow-root

    # Bài 5 (An ninh mạng & Hệ thống)
    P5=$(wp post create \
        --post_type=post \
        --post_status=publish \
        --post_title="Giải pháp giám sát toàn diện Web Server và Database bằng bộ đôi Prometheus - Grafana" \
        --post_name="giai-phap-giam-sat-toan-dien-web-server-database-prometheus-grafana" \
        --post_excerpt="Phân tích chi tiết cách thu thập chỉ số hoạt động từ Nginx stub_status, MySQL Exporter và cAdvisor để xây dựng bảng điều khiển cảnh báo sớm cho quản trị viên hệ thống." \
        --post_category="$CAT_ANNINHMANG" \
        --tags_input="Prometheus,Grafana,MySQL,Monitoring,SystemAdmin" \
        --post_content="<p>Trong vận hành hệ thống phần mềm, việc nắm bắt chính xác tình trạng tiêu thụ CPU, bộ nhớ RAM của từng container cũng như số lượng kết nối đồng thời tới Web Server và Database là yếu tố sống còn.</p><h2>Kiến trúc thu thập Metrics chuẩn</h2><ul><li><strong>cAdvisor:</strong> Thu thập chỉ số tài nguyên ở mức container (CPU usage, Memory working set, Network RX/TX).</li><li><strong>Nginx Prometheus Exporter:</strong> Đọc dữ liệu từ endpoint <code>/nginx_status</code> để thống kê số kết nối đang hoạt động (Active connections) và tổng số HTTP requests.</li><li><strong>MySQLd Exporter:</strong> Kết nối bằng tài khoản quyền tối thiểu để theo dõi <code>mysql_up</code>, số lượng truy vấn mỗi giây (QPS), Slow queries và InnoDB Buffer Pool.</li></ul><p>Toàn bộ dữ liệu chuỗi thời gian (Time-Series) được trực quan hóa trên Grafana Dashboard giúp quản trị viên nắm bắt sức khỏe hệ thống chỉ trong một màn hình duy nhất.</p>" \
        --porcelain --allow-root)
    wp post meta update "$P5" _vietnews_views_count 1410 --allow-root

    # Bài 6 (An ninh mạng & Hệ thống - Loki & LogQL)
    P6=$(wp post create \
        --post_type=post \
        --post_status=publish \
        --post_title="Quản lý nhật ký tập trung với Grafana Loki và Promtail: Truy vấn nhanh bằng ngôn ngữ LogQL" \
        --post_name="quan-ly-nhat-ky-tap-trung-grafana-loki-promtail-logql" \
        --post_excerpt="Thay vì phải đăng nhập vào từng container để đọc log thủ công, kiến trúc Loki + Promtail cho phép gom toàn bộ log ứng dụng, tìm kiếm lỗi 4xx/5xx và phát hiện tấn công ngay tức thì." \
        --post_category="$CAT_ANNINHMANG" \
        --tags_input="Loki,Promtail,LogQL,Logging,Bảo mật" \
        --post_content="<p>Khi hệ thống bao gồm nhiều dịch vụ chạy song song trên Docker Compose, việc tra cứu nguyên nhân lỗi từ hàng chục luồng log phân tán là một thách thức lớn. <strong>Grafana Loki</strong> giải quyết bài toán này bằng cách chỉ đánh chỉ mục (index) các nhãn metadata (labels) thay vì toàn văn, giúp tiết kiệm bộ nhớ nhưng vẫn đạt tốc độ truy vấn cực nhanh.</p><h2>Các truy vấn LogQL thiết yếu cho Quản trị viên</h2><p>Với ngôn ngữ <code>LogQL</code>, quản trị viên có thể lọc ngay toàn bộ truy cập vào trang quản trị hoặc phát hiện các mã lỗi bất thường:</p><ul><li>Truy vấn toàn bộ log của Reverse Proxy: <code>{service=\"nginx\"}</code></li><li>Lọc các sự kiện đăng nhập hoặc quản trị: <code>{service=\"wordpress\"} |= \"wp-\"</code></li><li>Thống kê tần suất log theo từng dịch vụ trong 5 phút: <code>sum by (service) (rate({job=\"docker-containers\"}[5m]))</code></li></ul>" \
        --porcelain --allow-root)
    wp post meta update "$P6" _vietnews_views_count 1285 --allow-root

    # Bài 7 (Giáo dục)
    P7=$(wp post create \
        --post_type=post \
        --post_status=publish \
        --post_title="Các trường đại học đẩy mạnh đào tạo thực hành DevSecOps và Quản trị hạ tầng đám mây" \
        --post_name="cac-truong-dai-hoc-day-manh-dao-tao-thuc-hanh-devsecops" \
        --post_excerpt="Sinh viên ngành Công nghệ thông tin được tiếp cận sớm với quy trình triển khai phần mềm thực tế: từ quản lý mã nguồn Git, đóng gói Docker cho đến bảo mật và giám sát hệ thống." \
        --post_category="$CAT_GIAODUC" \
        --tags_input="Giáo dục,CNTT,DevSecOps,Sinh viên" \
        --post_content="<p>Nhằm đáp ứng nhu cầu tuyển dụng khắt khe của doanh nghiệp, chương trình đào tạo học phần <strong>Triển khai và Quản trị Hệ thống Phần mềm</strong> đã chuyển dịch mạnh mẽ sang mô hình học qua dự án thực tế (Project-based Learning).</p><h2>Rèn luyện tư duy vận hành hệ thống thực chiến</h2><p>Thay vì chỉ học lý thuyết, sinh viên trực tiếp thiết kế kiến trúc mạng, cấu hình Reverse Proxy với chứng chỉ số SSL, thiết lập hệ thống theo dõi tài nguyên và viết báo cáo đánh giá an toàn thông tin toàn diện.</p>" \
        --porcelain --allow-root)
    wp post meta update "$P7" _vietnews_views_count 980 --allow-root

    # Bài 8 (Đời sống)
    P8=$(wp post create \
        --post_type=post \
        --post_status=publish \
        --post_title="Ứng dụng công nghệ xanh và IoT trong xây dựng không gian sống thông minh tại các đô thị lớn" \
        --post_name="ung-dung-cong-nghe-xanh-iot-khong-gian-song-thong-minh" \
        --post_excerpt="Hệ thống cảm biến chất lượng không khí, chiếu sáng tiết kiệm năng lượng và quản lý giao thông thông minh đang từng bước nâng cao chất lượng sống của cư dân đô thị." \
        --post_category="$CAT_DOISONG" \
        --tags_input="Đời sống,Đô thị thông minh,IoT,Công nghệ xanh" \
        --post_content="<p>Xu hướng kết hợp giữa thiết bị Internet vạn vật (IoT) và nền tảng phân tích dữ liệu đám mây đang giúp các khu đô thị mới tối ưu hóa tới 30% lượng điện năng tiêu thụ mỗi tháng.</p><p>Người dân có thể theo dõi chỉ số môi trường, đặt lịch sử dụng tiện ích công cộng và nhận cảnh báo giao thông trực tiếp qua ứng dụng di động kết nối với cổng thông tin thành phố.</p>" \
        --porcelain --allow-root)
    wp post meta update "$P8" _vietnews_views_count 845 --allow-root

    # Bài 9 (Công nghệ & AI)
    P9=$(wp post create \
        --post_type=post \
        --post_status=publish \
        --post_title="Kỹ thuật Hardening Nginx và Docker Container: Lá chắn vững chắc cho ứng dụng Web" \
        --post_name="ky-thuat-hardening-nginx-va-docker-container-cho-ung-dung-web" \
        --post_excerpt="Tổng hợp 6 biện pháp gia cố bảo mật quan trọng nhất: ẩn thông tin phiên bản, cấu hình Security Headers, giới hạn quyền truy cập DB, chạy Non-root và cô lập mạng nội bộ." \
        --post_category="$CAT_CONGNGHE,$CAT_ANNINHMANG" \
        --tags_input="Hardening,Nginx,Bảo mật Web,Docker Security" \
        --post_content="<p>Một ứng dụng web sau khi triển khai nếu giữ nguyên cấu hình mặc định sẽ tiềm ẩn nhiều rủi ro trước các cuộc tấn công tự động. Do đó, quy trình <strong>System Hardening (Gia cố bảo mật hệ thống)</strong> là bước bắt buộc trước khi đưa sản phẩm vào vận hành.</p><h2>Các lớp bảo vệ trọng yếu</h2><ol><li><strong>Tại tầng Reverse Proxy (Nginx):</strong> Tắt <code>server_tokens</code>, bật HTTPS/TLS 1.3, bổ sung <code>Strict-Transport-Security</code>, <code>X-Frame-Options</code>, <code>X-Content-Type-Options</code>, chặn <code>/xmlrpc.php</code> và giới hạn tần suất đăng nhập <code>/wp-login.php</code>.</li><li><strong>Tại tầng Container:</strong> Áp dụng <code>no-new-privileges:true</code>, <code>cap_drop: ALL</code>, giới hạn bộ nhớ RAM/CPU và chạy dịch vụ với tài khoản phi đặc quyền (Non-root).</li><li><strong>Tại tầng Mạng &amp; Cơ sở dữ liệu:</strong> Không mở cổng 3306 ra ngoài máy chủ, tách biệt <code>frontend_net</code> và <code>backend_net</code>, phân quyền tài khoản MySQL tối thiểu.</li></ol>" \
        --porcelain --allow-root)
    wp post meta update "$P9" _vietnews_views_count 1620 --allow-root

    # Bài 10 (Kinh tế - Tài chính)
    P10=$(wp post create \
        --post_type=post \
        --post_status=publish \
        --post_title="Doanh nghiệp vừa và nhỏ tối ưu chi phí hạ tầng CNTT nhờ giải pháp mã nguồn mở" \
        --post_name="doanh-nghiep-toi-uu-chi-phi-ha-tang-cntt-nho-ma-nguon-mo" \
        --post_excerpt="Việc lựa chọn hệ sinh thái mã nguồn mở gồm Linux, Docker, WordPress, MySQL, Nginx, Prometheus và Grafana giúp doanh nghiệp tiết kiệm hàng trăm triệu đồng chi phí bản quyền mỗi năm." \
        --post_category="$CAT_KINHTE" \
        --tags_input="Mã nguồn mở,Doanh nghiệp,Chi phí CNTT,Kinh tế" \
        --post_content="<p>Thay vì phụ thuộc vào các giải pháp thương mại đắt đỏ, ngày càng nhiều doanh nghiệp vừa và nhỏ (SME) tại Việt Nam xây dựng hạ tầng công nghệ thông tin dựa trên các phần mềm mã nguồn mở uy tín toàn cầu.</p><p>Không chỉ miễn phí bản quyền, cộng đồng hỗ trợ rộng lớn và khả năng tùy biến linh hoạt giúp doanh nghiệp hoàn toàn làm chủ dữ liệu và hạ tầng kỹ thuật của mình.</p>" \
        --porcelain --allow-root)
    wp post meta update "$P10" _vietnews_views_count 910 --allow-root

    # Đánh dấu 4 bài viết đầu tiên là Bài viết Nổi bật (Sticky Posts)
    wp post stick "$P1" "$P2" "$P3" "$P4" --allow-root

    echo "  -> Đã khởi tạo thành công 10 bài viết mẫu Tiếng Việt và gắn 4 bài Nổi bật!"
else
    echo "[6/6] Dữ liệu bài viết mẫu đã tồn tại ($POST_COUNT bài viết). Bỏ qua bước tạo mới."
fi

echo "=================================================================="
echo "[VietNews 24h Setup] HOÀN TẤT KHỞI TẠO WEBSITE TIN TỨC ĐỀ 19!"
echo "=================================================================="
