<?php
/**
 * Trang Đọc Bài Viết Chi Tiết (Single Post View)
 * Đề 19: Website Tin tức / Cổng thông tin
 */
get_header();
?>

<main class="vn-container" style="margin-top: 28px;">
    <div class="vn-main-layout">
        <div class="vn-content-col">
            <?php
            while (have_posts()) :
                the_post();
                vietnews_increment_views(get_the_ID());
                $categories = get_the_category();
            ?>
                <article id="post-<?php the_ID(); ?>" <?php post_class('vn-article-box'); ?>>
                    <!-- Breadcrumb điều hướng -->
                    <nav class="vn-breadcrumb" aria-label="Breadcrumb">
                        <a href="<?php echo esc_url(home_url('/')); ?>">Trang chủ</a>
                        <?php if (!empty($categories)) : ?>
                            &rsaquo; <a href="<?php echo esc_url(get_category_link($categories[0]->term_id)); ?>"><?php echo esc_html($categories[0]->name); ?></a>
                        <?php endif; ?>
                        &rsaquo; <span><?php the_title(); ?></span>
                    </nav>

                    <!-- Nhãn chuyên mục & Bài nổi bật -->
                    <div class="vn-badge-row">
                        <?php vietnews_category_badge(get_the_ID()); ?>
                        <?php if (is_sticky(get_the_ID())) : ?>
                            <span class="vn-featured-badge">&#9733; BÀI VIẾT NỔI BẬT</span>
                        <?php endif; ?>
                    </div>

                    <!-- Tiêu đề bài báo -->
                    <h1 class="vn-article-title"><?php the_title(); ?></h1>

                    <!-- Thông tin tác giả, thời gian, lượt xem & nút Sửa nhanh cho Admin -->
                    <div class="vn-article-meta">
                        <div>
                            <strong>Tác giả: <?php the_author(); ?></strong>
                            <span> &bull; Đăng ngày: <?php echo get_the_date('d/m/Y H:i'); ?></span>
                            <span> &bull; <?php echo esc_html(vietnews_reading_time(get_the_ID())); ?></span>
                            <span> &bull; <?php echo esc_html(vietnews_get_views(get_the_ID())); ?> lượt xem</span>
                        </div>
                        <?php if (current_user_can('edit_post', get_the_ID())) : ?>
                            <a href="<?php echo esc_url(get_edit_post_link()); ?>" style="color: #dc2626; font-weight: 700;">
                                &#9998; Sửa bài viết này
                            </a>
                        <?php endif; ?>
                    </div>

                    <!-- Ảnh bìa bài báo -->
                    <div class="vn-article-featured-img">
                        <?php vietnews_render_thumbnail(get_the_ID(), 'large'); ?>
                    </div>

                    <!-- Đoạn Sapo (Tóm tắt bài viết) -->
                    <?php if (has_excerpt()) : ?>
                        <div class="vn-article-lead">
                            <?php echo esc_html(get_the_excerpt()); ?>
                        </div>
                    <?php endif; ?>

                    <!-- Nội dung chi tiết bài viết -->
                    <div class="vn-article-content">
                        <?php the_content(); ?>
                    </div>

                    <!-- Thẻ Tags & Chuyên mục -->
                    <div class="vn-tags-box">
                        <strong style="font-size: 14px;">Chuyên mục:</strong>
                        <?php foreach ($categories as $cat) : ?>
                            <a class="vn-tag-pill" href="<?php echo esc_url(get_category_link($cat->term_id)); ?>">
                                #<?php echo esc_html($cat->name); ?>
                            </a>
                        <?php endforeach; ?>
                        <?php
                        $tags = get_the_tags();
                        if ($tags) :
                            foreach ($tags as $tag) :
                        ?>
                            <a class="vn-tag-pill" href="<?php echo esc_url(get_tag_link($tag->term_id)); ?>">
                                #<?php echo esc_html($tag->name); ?>
                            </a>
                        <?php
                            endforeach;
                        endif;
                        ?>
                    </div>
                </article>

                <!-- Bài viết cùng chuyên mục -->
                <?php
                if (!empty($categories)) :
                    $related_query = new WP_Query(array(
                        'category__in'        => array($categories[0]->term_id),
                        'post__not_in'        => array(get_the_ID()),
                        'posts_per_page'      => 4,
                        'ignore_sticky_posts' => true,
                    ));
                    if ($related_query->have_posts()) :
                ?>
                    <section style="margin-bottom: 32px;">
                        <div class="vn-section-header">
                            <h2 class="vn-section-title">BÀI VIẾT CÙNG CHUYÊN MỤC</h2>
                        </div>
                        <div class="vn-news-grid">
                            <?php while ($related_query->have_posts()) : $related_query->the_post(); ?>
                                <article class="vn-news-card">
                                    <a href="<?php the_permalink(); ?>" class="vn-thumb-wrap">
                                        <?php vietnews_render_thumbnail(get_the_ID(), 'medium'); ?>
                                    </a>
                                    <div class="vn-news-card-body">
                                        <div>
                                            <div class="vn-badge-row">
                                                <?php vietnews_category_badge(get_the_ID()); ?>
                                            </div>
                                            <h3 class="vn-news-card-title">
                                                <a href="<?php the_permalink(); ?>"><?php the_title(); ?></a>
                                            </h3>
                                        </div>
                                        <div class="vn-meta">
                                            <span><?php echo get_the_date('d/m/Y'); ?></span>
                                            <span>&bull; <?php echo esc_html(vietnews_get_views(get_the_ID())); ?> xem</span>
                                        </div>
                                    </div>
                                </article>
                            <?php endwhile; ?>
                        </div>
                    </section>
                <?php
                    endif;
                    wp_reset_postdata();
                endif;
                ?>

            <?php endwhile; ?>
        </div>

        <?php get_sidebar(); ?>
    </div>
</main>

<?php get_footer(); ?>
