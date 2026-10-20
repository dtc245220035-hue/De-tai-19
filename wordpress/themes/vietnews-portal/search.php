<?php
/**
 * Trang Kết Quả Tìm Kiếm Bài Viết (Search Results View)
 * Đề 19: Website Tin tức / Cổng thông tin
 */
get_header();
global $wp_query;
?>

<main class="vn-container">
    <!-- Banner Tìm Kiếm -->
    <section class="vn-archive-banner">
        <div style="font-size: 12px; text-transform: uppercase; letter-spacing: 1px; color: #93c5fd; margin-bottom: 6px; font-weight: 700;">
            TÌM KIẾM TRÊN CỔNG THÔNG TIN VIETNEWS 24H
        </div>
        <h1>Kết quả tìm kiếm cho từ khóa: &ldquo;<?php echo esc_html(get_search_query()); ?>&rdquo;</h1>
        <p>Tìm thấy <strong><?php echo intval($wp_query->found_posts); ?></strong> bài viết phù hợp với nội dung truy vấn của bạn.</p>
    </section>

    <div class="vn-main-layout">
        <div class="vn-content-col">
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
                                        <?php echo esc_html(wp_trim_words(get_the_excerpt(), 26, '...')); ?>
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
                    <h3 style="margin-bottom: 10px;">Không tìm thấy bài viết nào khớp với từ khóa &ldquo;<?php echo esc_html(get_search_query()); ?>&rdquo;</h3>
                    <p style="margin-bottom: 16px; color: #475569;">Bạn có thể thử tìm kiếm lại bằng các từ khóa gợi ý như: <strong>AI</strong>, <strong>Docker</strong>, <strong>Kinh tế</strong>, <strong>An ninh mạng</strong>, <strong>Chuyển đổi số</strong>, <strong>Giáo dục</strong>.</p>
                    <form role="search" method="get" class="vn-search-form" action="<?php echo esc_url(home_url('/')); ?>" style="max-width: 460px;">
                        <input type="search" class="vn-search-input" placeholder="Nhập từ khóa khác..." value="<?php echo get_search_query(); ?>" name="s" required />
                        <button type="submit" class="vn-search-submit">Tìm kiếm lại</button>
                    </form>
                </div>
            <?php endif; ?>
        </div>

        <?php get_sidebar(); ?>
    </div>
</main>

<?php get_footer(); ?>
