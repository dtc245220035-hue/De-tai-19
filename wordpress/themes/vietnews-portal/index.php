<?php
/**
 * Trang chủ Cổng thông tin VietNews 24h
 * Hiển thị:
 * 1. Khu vực Bài viết Nổi bật (Featured Hero: 1 bài chính + 3 bài tiêu điểm phụ)
 * 2. Khu vực Bài viết Mới nhất (Latest News Grid)
 * 3. Khu vực Tin tức theo từng Danh mục (Category Spotlights)
 * 4. Thanh bên (Sidebar): Tìm kiếm, Danh mục, Tin đọc nhiều
 */
get_header();
?>

<main class="vn-container">
    <?php
    // Lấy danh sách bài viết nổi bật (Sticky Posts hoặc 4 bài mới nhất nếu chưa ghim)
    $sticky_ids = get_option('sticky_posts');
    $featured_args = array(
        'post_type'           => 'post',
        'post_status'         => 'publish',
        'posts_per_page'      => 4,
        'ignore_sticky_posts' => true,
    );
    if (!empty($sticky_ids)) {
        $featured_args['post__in'] = $sticky_ids;
        $featured_args['orderby']  = 'post__in';
    }
    $featured_query = new WP_Query($featured_args);
    $featured_posts = $featured_query->posts;

    // Nếu số bài sticky ít hơn 4, bổ sung thêm bài mới nhất để khu vực Hero luôn đủ 4 bài
    if (count($featured_posts) < 4) {
        $exclude_ids = wp_list_pluck($featured_posts, 'ID');
        $fill_query = new WP_Query(array(
            'post_type'           => 'post',
            'post_status'         => 'publish',
            'posts_per_page'      => 4 - count($featured_posts),
            'post__not_in'        => $exclude_ids,
            'ignore_sticky_posts' => true,
        ));
        $featured_posts = array_merge($featured_posts, $fill_query->posts);
    }
    ?>

    <?php if (!empty($featured_posts) && !is_paged()) : ?>
    <!-- PHẦN 1: BÀI VIẾT NỔI BẬT (FEATURED STORIES) -->
    <section class="vn-hero-section" aria-label="Bài viết nổi bật">
        <div class="vn-section-header">
            <h2 class="vn-section-title">BÀI VIẾT NỔI BẬT &amp; TIÊU ĐIỂM</h2>
            <span style="font-size: 13px; color: #64748b; font-weight: 600;">Cập nhật liên tục 24/7</span>
        </div>

        <div class="vn-hero-grid">
            <?php
            // Bài nổi bật chính (Main Hero Story)
            $main_post = $featured_posts[0];
            setup_postdata($GLOBALS['post'] =& $main_post);
            ?>
            <article class="vn-hero-main">
                <a href="<?php the_permalink(); ?>" class="vn-thumb-wrap">
                    <?php vietnews_render_thumbnail(get_the_ID(), 'large'); ?>
                </a>
                <div class="vn-hero-main-body">
                    <div>
                        <div class="vn-badge-row">
                            <span class="vn-featured-badge">&#9733; TIN NỔI BẬT</span>
                            <?php vietnews_category_badge(get_the_ID()); ?>
                        </div>
                        <h3 class="vn-hero-main-title">
                            <a href="<?php the_permalink(); ?>"><?php the_title(); ?></a>
                        </h3>
                        <p class="vn-hero-main-excerpt">
                            <?php echo esc_html(wp_trim_words(get_the_excerpt(), 36, '...')); ?>
                        </p>
                    </div>
                    <div class="vn-meta">
                        <span><strong><?php the_author(); ?></strong></span>
                        <span>&bull; <?php echo get_the_date('d/m/Y H:i'); ?></span>
                        <span>&bull; <?php echo esc_html(vietnews_reading_time(get_the_ID())); ?></span>
                        <span>&bull; <?php echo esc_html(vietnews_get_views(get_the_ID())); ?> lượt xem</span>
                    </div>
                </div>
            </article>
            <?php wp_reset_postdata(); ?>

            <!-- 3 Bài nổi bật phụ bên phải -->
            <div class="vn-hero-side">
                <?php
                for ($i = 1; $i < count($featured_posts); $i++) :
                    $side_post = $featured_posts[$i];
                    setup_postdata($GLOBALS['post'] =& $side_post);
                ?>
                    <article class="vn-side-card">
                        <a href="<?php the_permalink(); ?>" class="vn-thumb-wrap">
                            <?php vietnews_render_thumbnail(get_the_ID(), 'medium'); ?>
                        </a>
                        <div>
                            <div class="vn-badge-row" style="margin-bottom: 4px;">
                                <?php vietnews_category_badge(get_the_ID()); ?>
                            </div>
                            <h3 class="vn-side-card-title">
                                <a href="<?php the_permalink(); ?>"><?php the_title(); ?></a>
                            </h3>
                            <div class="vn-meta" style="font-size: 12px;">
                                <span><?php echo get_the_date('d/m/Y'); ?></span>
                                <span>&bull; <?php echo esc_html(vietnews_get_views(get_the_ID())); ?> lượt xem</span>
                            </div>
                        </div>
                    </article>
                <?php
                endfor;
                wp_reset_postdata();
                ?>
            </div>
        </div>
    </section>
    <?php endif; ?>

    <!-- PHẦN 2: BỐ CỤC CHÍNH (DANH SÁCH BÀI VIẾT MỚI NHẤT + SIDEBAR) -->
    <div class="vn-main-layout">
        <div class="vn-content-col">
            <div class="vn-section-header">
                <h2 class="vn-section-title">BÀI VIẾT MỚI NHẤT</h2>
                <span style="font-size: 13px; color: #64748b;">Tổng hợp toàn bộ tin tức mới</span>
            </div>

            <?php
            $latest_query = new WP_Query(array(
                'post_type'           => 'post',
                'post_status'         => 'publish',
                'posts_per_page'      => 10,
                'paged'               => max(1, get_query_var('paged')),
                'ignore_sticky_posts' => true,
            ));

            if ($latest_query->have_posts()) :
            ?>
                <div class="vn-news-grid">
                    <?php while ($latest_query->have_posts()) : $latest_query->the_post(); ?>
                        <article id="post-<?php the_ID(); ?>" <?php post_class('vn-news-card'); ?>>
                            <a href="<?php the_permalink(); ?>" class="vn-thumb-wrap">
                                <?php vietnews_render_thumbnail(get_the_ID(), 'medium_large'); ?>
                            </a>
                            <div class="vn-news-card-body">
                                <div>
                                    <div class="vn-badge-row">
                                        <?php vietnews_category_badge(get_the_ID()); ?>
                                        <?php if (is_sticky(get_the_ID())) : ?>
                                            <span class="vn-featured-badge">Nổi bật</span>
                                        <?php endif; ?>
                                    </div>
                                    <h3 class="vn-news-card-title">
                                        <a href="<?php the_permalink(); ?>"><?php the_title(); ?></a>
                                    </h3>
                                    <p class="vn-news-card-excerpt">
                                        <?php echo esc_html(wp_trim_words(get_the_excerpt(), 24, '...')); ?>
                                    </p>
                                </div>
                                <div class="vn-meta">
                                    <span><?php echo get_the_date('d/m/Y'); ?></span>
                                    <span>&bull; <?php echo esc_html(vietnews_reading_time(get_the_ID())); ?></span>
                                    <span>&bull; <?php echo esc_html(vietnews_get_views(get_the_ID())); ?> xem</span>
                                </div>
                            </div>
                        </article>
                    <?php endwhile; ?>
                </div>

                <div class="vn-pagination">
                    <?php
                    echo paginate_links(array(
                        'total'     => $latest_query->max_num_pages,
                        'prev_text' => '&laquo; Trang trước',
                        'next_text' => 'Trang sau &raquo;',
                    ));
                    ?>
                </div>
            <?php
                wp_reset_postdata();
            else :
            ?>
                <div class="vn-article-box">
                    <h3>Chưa có bài viết nào được xuất bản</h3>
                    <p>Hãy đăng nhập vào trang Quản trị WordPress để đăng bài viết mới.</p>
                </div>
            <?php endif; ?>
        </div>

        <!-- Cột Sidebar -->
        <?php get_sidebar(); ?>
    </div>
</main>

<?php get_footer(); ?>
