<?php
/**
 * Trang Danh Mục Tin Tức (Category Archive View)
 * Đề 19: Website Tin tức / Cổng thông tin
 */
get_header();
$current_cat = get_queried_object();
?>

<main class="vn-container">
    <!-- Banner Chuyên Mục -->
    <section class="vn-archive-banner">
        <div style="font-size: 12px; text-transform: uppercase; letter-spacing: 1px; color: #93c5fd; margin-bottom: 6px; font-weight: 700;">
            CHUYÊN MỤC TIN TỨC
        </div>
        <h1><?php single_cat_title(); ?></h1>
        <?php if (category_description()) : ?>
            <div><?php echo category_description(); ?></div>
        <?php else : ?>
            <p>Tổng hợp các bài viết, phân tích và tin tức mới nhất thuộc chuyên mục <?php single_cat_title(); ?>.</p>
        <?php endif; ?>
    </section>

    <div class="vn-main-layout">
        <div class="vn-content-col">
            <div class="vn-section-header">
                <h2 class="vn-section-title">DANH SÁCH BÀI VIẾT: <?php single_cat_title(); ?></h2>
                <?php if (isset($current_cat->count)) : ?>
                    <span style="font-size: 13px; color: #64748b; font-weight: 600;">Có <?php echo intval($current_cat->count); ?> bài viết</span>
                <?php endif; ?>
            </div>

            <?php if (have_posts()) : ?>
                <div class="vn-news-grid">
                    <?php while (have_posts()) : the_post(); ?>
                        <article id="post-<?php the_ID(); ?>" <?php post_class('vn-news-card'); ?>>
                            <a href="<?php the_permalink(); ?>" class="vn-thumb-wrap">
                                <?php vietnews_render_thumbnail(get_the_ID(), 'medium_large'); ?>
                            </a>
                            <div class="vn-news-card-body">
                                <div>
                                    <div class="vn-badge-row">
                                        <?php vietnews_category_badge(get_the_ID()); ?>
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
                        'prev_text' => '&laquo; Trang trước',
                        'next_text' => 'Trang sau &raquo;',
                    ));
                    ?>
                </div>
            <?php else : ?>
                <div class="vn-article-box">
                    <h3>Chưa có bài viết trong chuyên mục này</h3>
                    <p>Quản trị viên có thể thêm bài viết mới vào chuyên mục từ trang WP-Admin.</p>
                </div>
            <?php endif; ?>
        </div>

        <?php get_sidebar(); ?>
    </div>
</main>

<?php get_footer(); ?>
