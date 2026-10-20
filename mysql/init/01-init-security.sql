-- ==============================================================================
-- SCRIPT KHỞI TẠO & PHÂN QUYỀN TỐI THIỂU (LEAST PRIVILEGE) CHO MYSQL 8.0
-- Đề 19: Website Tin tức / Cổng thông tin (VietNews 24h)
-- ==============================================================================

-- 1. Đảm bảo cơ sở dữ liệu chính sử dụng chuẩn utf8mb4 hỗ trợ tiếng Việt
CREATE DATABASE IF NOT EXISTS `vietnews_db`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- 2. Phân quyền tối thiểu cho tài khoản ứng dụng WordPress (chỉ có quyền trên vietnews_db)
CREATE USER IF NOT EXISTS 'wp_news_user'@'%' IDENTIFIED BY 'VnNews#App$2026!WpUsr88';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER
  ON `vietnews_db`.* TO 'wp_news_user'@'%';

-- 3. Tạo tài khoản chuyên biệt chỉ đọc Metrics cho Prometheus MySQL Exporter
-- Áp dụng nguyên tắc Least Privilege: Không có quyền đọc dữ liệu bảng của ứng dụng (vietnews_db),
-- chỉ có quyền PROCESS, REPLICATION CLIENT và SELECT trên performance_schema, giới hạn tối đa 5 kết nối.
CREATE USER IF NOT EXISTS 'exporter_user'@'%'
  IDENTIFIED BY 'VnNews#Exp$2026!Metric77'
  WITH MAX_USER_CONNECTIONS 5;

GRANT PROCESS, REPLICATION CLIENT ON *.* TO 'exporter_user'@'%';
GRANT SELECT ON `performance_schema`.* TO 'exporter_user'@'%';

-- 4. Xóa các tài khoản ẩn danh (nếu có) và áp dụng quyền
DELETE FROM mysql.user WHERE User='';
FLUSH PRIVILEGES;
