<!DOCTYPE html>
<html <?php language_attributes(); ?>>
<head>
    <meta charset="<?php bloginfo('charset'); ?>">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>
<?php wp_body_open(); ?>

<!-- Thanh tiện ích trên cùng (Top Utility Bar) -->
<div class="vn-topbar">
    <div class="vn-container vn-topbar-inner">
        <div class="vn-topbar-left">
            <span class="vn-breaking-badge">TIN NÓNG 24H</span>
            <span class="vn-date-label"><?php echo esc_html(vietnews_current_date_vi()); ?></span>
        </div>
        <div class="vn-topbar-right">
            <a href="<?php echo esc_url(home_url('/')); ?>">Trang chủ</a>
            <a href="<?php echo esc_url(home_url('/?feed=rss2')); ?>">RSS</a>
            <?php if (is_user_logged_in()) : ?>
                <a class="vn-admin-btn" href="<?php echo esc_url(admin_url('post-new.php')); ?>">+ Đăng bài viết mới</a>
                <a href="<?php echo esc_url(admin_url()); ?>">Bảng quản trị (WP-Admin)</a>
            <?php else : ?>
                <a class="vn-admin-btn" href="<?php echo esc_url(wp_login_url()); ?>">Đăng nhập Quản trị</a>
            <?php endif; ?>
        </div>
    </div>
</div>

<!-- Header chính (Logo & Thanh tìm kiếm bài viết) -->
<header class="vn-header">
    <div class="vn-container vn-header-inner">
        <a class="vn-brand" href="<?php echo esc_url(home_url('/')); ?>">
            <div class="vn-logo-mark">VN</div>
            <div class="vn-brand-text">
                <h1>VIET<span>NEWS</span> 24H</h1>
                <div class="vn-brand-tagline">Cổng Thông Tin Điện Tử Tổng Hợp - Đề tài 19 Quản Trị Hệ Thống</div>
            </div>
        </a>

        <div class="vn-header-search">
            <form role="search" method="get" class="vn-search-form" action="<?php echo esc_url(home_url('/')); ?>">
                <input type="search" class="vn-search-input" placeholder="Tìm kiếm bài viết, chủ đề, sự kiện..." value="<?php echo get_search_query(); ?>" name="s" required />
                <button type="submit" class="vn-search-submit">Tìm kiếm</button>
            </form>
        </div>
    </div>
</header>

<!-- Thanh điều hướng Danh mục tin tức (Category Navigation) -->
<nav class="vn-navbar" aria-label="Danh mục tin tức">
    <div class="vn-container">
        <ul class="vn-nav-list">
            <li class="vn-nav-item <?php echo is_front_page() || is_home() ? 'active' : ''; ?>">
                <a href="<?php echo esc_url(home_url('/')); ?>">Trang chủ</a>
            </li>
            <?php
            $categories = get_categories(array(
                'orderby'    => 'id',
                'order'      => 'ASC',
                'hide_empty' => false,
            ));
            foreach ($categories as $cat) :
                if ($cat->slug === 'uncategorized') continue;
                $is_active = is_category($cat->term_id) ? 'active' : '';
            ?>
                <li class="vn-nav-item <?php echo esc_attr($is_active); ?>">
                    <a href="<?php echo esc_url(get_category_link($cat->term_id)); ?>">
                        <?php echo esc_html($cat->name); ?>
                    </a>
                </li>
            <?php endforeach; ?>
        </ul>
    </div>
</nav>
