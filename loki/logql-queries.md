# Danh sách Truy vấn LogQL Thực Tế - Đề 19: Website Tin tức VietNews 24h

Tài liệu này cung cấp **6 câu truy vấn LogQL chạy được thực tế** trên hệ thống **Grafana Loki + Promtail** của dự án. Bạn có thể chạy trực tiếp tại giao diện **Grafana (`http://127.0.0.1:3000`) -> Explore -> Chọn Datasource: `Loki`** hoặc qua REST API của Loki (`http://127.0.0.1:3100`).

---

## Truy vấn 1: Xem toàn bộ nhật ký truy cập và hoạt động của Nginx Reverse Proxy
```logql
{service="nginx"}
```
- **Ý nghĩa:** Thu thập tất cả dòng log từ dịch vụ `nginx` (bao gồm cả stdout/stderr của container `vietnews-nginx` và file `/var/log/nginx/access.log`, `error.log`).
- **Ứng dụng thực tế:** Giám sát lưu lượng người dùng truy cập trang chủ, chuyên mục, bài viết, mã phản hồi HTTP (`200`, `301`, `403`, `404`) và thời gian xử lý upstream (`rt=`, `urt=`).

---

## Truy vấn 2: Lọc các truy cập vào trang Quản trị WordPress (`/wp-admin`, `/wp-login.php`)
```logql
{service="wordpress"} |~ "wp-(admin|login)"
```
*(Hoặc trên luồng Nginx: `{service="nginx"} |~ "wp-(admin|login)"`)*
- **Ý nghĩa:** Sử dụng biểu thức chính quy (Regex `|~`) để lọc toàn bộ các HTTP request liên quan đến đăng nhập (`/wp-login.php`) và thao tác quản trị bài viết/danh mục (`/wp-admin`).
- **Ứng dụng thực tế:** Kiểm toán bảo mật (Security Audit), theo dõi hoạt động của Admin/Biên tập viên và phát hiện sớm các hành vi dò mật khẩu (Brute-force).

---

## Truy vấn 3: Phát hiện các sự kiện bị chặn bảo mật hoặc lỗi HTTP (403, 404, 429, 5xx)
```logql
{service="nginx"} |~ "\" (403|404|429|500|502|503) "
```
- **Ý nghĩa:** Lọc các bản ghi Access Log của Nginx có mã trạng thái HTTP thuộc nhóm lỗi Client (`403 Forbidden` khi chặn `/xmlrpc.php`, `/wp-config.php`; `404 Not Found`; `429 Too Many Requests` khi vượt ngưỡng Rate Limit) hoặc lỗi Server (`5xx`).
- **Ứng dụng thực tế:** Xác minh hiệu quả của các quy tắc **Hardening trên Nginx** khi chặn truy cập trái phép vào các tệp nhạy cảm.

---

## Truy vấn 4: Theo dõi nhật ký khởi tạo và hoạt động của Cơ sở dữ liệu MySQL 8.0
```logql
{service="mysql"}
```
- **Ý nghĩa:** Truy xuất toàn bộ nhật ký hệ thống từ container `vietnews-mysql` (`stdout`/`stderr`).
- **Ứng dụng thực tế:** Kiểm tra quá trình khởi động InnoDB, trạng thái sẵn sàng kết nối (`ready for connections`), cảnh báo cấu hình hoặc truy vấn bất thường.

---

## Truy vấn 5: Thống kê tốc độ sinh Log (Logs/giây) theo từng Dịch vụ trong 5 phút gần nhất (Metric Query)
```logql
sum by (service) (rate({job="docker-containers"}[5m]))
```
- **Ý nghĩa:** Truy vấn dạng số liệu (LogQL Metric Query) tính tốc độ dòng log trung bình mỗi giây (`rate`) gom nhóm theo từng `service` (`nginx`, `wordpress`, `mysql`, `prometheus`, `grafana`, `loki`...).
- **Ứng dụng thực tế:** Biểu diễn dưới dạng biểu đồ Time-Series trên Grafana để phát hiện dịch vụ nào đang phát sinh log đột biến.

---

## Truy vấn 6: Đếm tổng số lượng Request/Log theo từng Container trong 15 phút qua
```logql
sum by (container) (count_over_time({job="docker-containers"}[15m]))
```
- **Ý nghĩa:** Đếm tổng số dòng nhật ký phát sinh của mỗi container trong khoảng thời gian 15 phút.
- **Ứng dụng thực tế:** Đánh giá mức độ hoạt động của từng container trong toàn bộ kiến trúc Docker Compose.
