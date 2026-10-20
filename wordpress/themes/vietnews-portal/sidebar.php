<aside class="vn-sidebar" aria-label="Thanh bên cổng thông tin">
    <!-- Widget 1: Tìm kiếm nhanh -->
    <div class="vn-widget">
        <h3 class="vn-widget-title">Tìm kiếm bài viết</h3>
        <form role="search" method="get" class="vn-search-form" action="<?php echo esc_url(home_url('/')); ?>">
            <input type="search" class="vn-search-input" placeholder="Nhập từ khóa tin tức..." value="<?php echo get_search_query(); ?>" name="s" required />
            <button type="submit" class="vn-search-submit">Tìm</button>
        </form>
    </div>

    <!-- Widget 2: Danh mục tin tức -->
    <div class="vn-widget">
        <h3 class="vn-widget-title">Danh mục tin tức</h3>
        <ul class="vn-cat-list">
            <?php
            $sidebar_cats = get_categories(array(
                'orderby'    => 'id',
                'order'      => 'ASC',
                'hide_empty' => false,
            ));
            foreach ($sidebar_cats as $cat) :
                if ($cat->slug === 'uncategorized' && $cat->count == 0) continue;
            ?>
                <li>
                    <a href="<?php echo esc_url(get_category_link($cat->term_id)); ?>">
                        <span><?php echo esc_html($cat->name); ?></span>
                        <span class="vn-cat-count"><?php echo intval($cat->count); ?></span>
                    </a>
                </li>
            <?php endforeach; ?>
        </ul>
    </div>

    <!-- Widget 3: Tin đọc nhiều / Tiêu điểm -->
    <div class="vn-widget">
        <h3 class="vn-widget-title">Đọc nhiều nhất</h3>
        <ul class="vn-popular-list">
            <?php
            $popular_query = new WP_Query(array(
                'post_type'           => 'post',
                'post_status'         => 'publish',
                'posts_per_page'      => 5,
                'ignore_sticky_posts' => true,
            ));
            $rank = 1;
            if ($popular_query->have_posts()) :
                while ($popular_query->have_posts()) : $popular_query->the_post();
            ?>
                <li class="vn-popular-item">
                    <span class="vn-rank-num"><?php echo intval($rank++); ?></span>
                    <div>
                        <h4 class="vn-popular-title">
                            <a href="<?php the_permalink(); ?>"><?php the_title(); ?></a>
                        </h4>
                        <div class="vn-meta" style="margin-top: 4px; font-size: 12px;">
                            <span><?php echo get_the_date('d/m/Y'); ?></span>
                            <span>&bull; <?php echo esc_html(vietnews_get_views()); ?> lượt xem</span>
                        </div>
                    </div>
                </li>
            <?php
                endwhile;
                wp_reset_postdata();
            endif;
            ?>
        </ul>
    </div>

    <!-- Widget 4: Trạng thái Hạ tầng Hệ thống (Hỗ trợ Demo Bảo Vệ Đồ Án) -->
    <div class="vn-widget" style="background: #0f172a; color: #f8fafc; border-color: #1e293b;">
        <h3 class="vn-widget-title" style="color: #fff; border-bottom-color: #1e293b;">Hạ tầng Hệ thống (Đề 19)</h3>
        <ul style="list-style: none; font-size: 13px; display: flex; flex-direction: column; gap: 8px; color: #cbd5e1;">
            <li><strong style="color: #4ade80;">&#9679; Reverse Proxy:</strong> Nginx (HTTPS / Security Headers)</li>
            <li><strong style="color: #4ade80;">&#9679; Ứng dụng:</strong> WordPress Official Image</li>
            <li><strong style="color: #4ade80;">&#9679; Cơ sở dữ liệu:</strong> MySQL 8.0 + phpMyAdmin</li>
            <li><strong style="color: #38bdf8;">&#9679; Giám sát:</strong> Prometheus + Grafana + Exporters</li>
            <li><strong style="color: #f472b6;">&#9679; Tập trung Log:</strong> Loki + Promtail (LogQL)</li>
            <li><strong style="color: #facc15;">&#9679; Hardening:</strong> Non-root, Network Isolation, Least Privilege</li>
        </ul>
    </div>
</aside>
