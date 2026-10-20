<footer class="vn-footer">
    <div class="vn-container">
        <div class="vn-footer-grid">
            <div>
                <h3>VIETNEWS 24H - CỔNG THÔNG TIN ĐIỆN TỬ</h3>
                <p>Hệ thống Website Tin tức & Cổng thông tin điện tử triển khai trên nền tảng Container hóa (Docker Compose) phục vụ Đề tài 19 - Môn Triển khai và Quản trị Hệ thống Phần mềm.</p>
                <p style="margin-top: 10px;">Kiến trúc tích hợp: <strong>Nginx Reverse Proxy (HTTPS + Security Headers)</strong> &bull; <strong>WordPress CMS</strong> &bull; <strong>MySQL 8.0 + phpMyAdmin</strong> &bull; <strong>Prometheus + Grafana</strong> &bull; <strong>Loki + Promtail</strong>.</p>
            </div>

            <div>
                <h3>CHUYÊN MỤC TIN TỨC</h3>
                <ul>
                    <?php
                    $cats = get_categories(array('hide_empty' => false));
                    foreach ($cats as $c) :
                        if ($c->slug === 'uncategorized') continue;
                    ?>
                        <li style="margin-bottom: 6px;">
                            <a href="<?php echo esc_url(get_category_link($c->term_id)); ?>">
                                &rsaquo; <?php echo esc_html($c->name); ?> (<?php echo intval($c->count); ?> bài)
                            </a>
                        </li>
                    <?php endforeach; ?>
                </ul>
            </div>

            <div>
                <h3>LIÊN KẾT QUẢN TRỊ & DEMO</h3>
                <ul>
                    <li style="margin-bottom: 6px;"><a href="<?php echo esc_url(admin_url()); ?>">&rsaquo; Trang Quản trị WordPress (/wp-admin)</a></li>
                    <li style="margin-bottom: 6px;"><a href="<?php echo esc_url(admin_url('edit.php')); ?>">&rsaquo; Quản lý Bài viết (Đăng / Sửa / Xóa)</a></li>
                    <li style="margin-bottom: 6px;"><a href="<?php echo esc_url(admin_url('edit-tags.php?taxonomy=category')); ?>">&rsaquo; Quản lý Danh mục Tin tức</a></li>
                    <li style="margin-bottom: 6px;"><a href="<?php echo esc_url(home_url('/?s=Docker')); ?>">&rsaquo; Thử nghiệm Tìm kiếm ("Docker")</a></li>
                </ul>
            </div>
        </div>

        <div class="vn-footer-bottom">
            <span>&copy; <?php echo date('Y'); ?> VietNews 24h Portal - Đề 19: Website Tin tức / Cổng thông tin.</span>
            <span>Bảo mật bởi Nginx TLS 1.3 Reverse Proxy &bull; Giám sát thời gian thực với Prometheus, Grafana &amp; Loki.</span>
        </div>
    </div>
</footer>

<?php wp_footer(); ?>
</body>
</html>
