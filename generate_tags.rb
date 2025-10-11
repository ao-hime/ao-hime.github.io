#!/usr/bin/env ruby
# Script pour générer les pages de tags à partir des métadonnées des chapitres

require 'fileutils'
require 'yaml'

# Configuration des langues
LANGUAGES = {
  'fr' => {
    'book_path' => 'cent-histoires-de-la-region-du-kansai',
    'book_title' => 'Cent Histoires de la Région du Kansai',
    'subtitle' => 'La Princesse Bleue',
    'back_home' => "Retour à l'accueil",
    'back_to_toc' => "Retour à la table des matières",
    'chapter' => 'Chapitre',
    'narrator' => 'Narrateur',
    'district' => 'District',
    'tags_index_title' => 'Index des thèmes',
    'tags_index_desc' => 'Explorez les récits par thème',
    'tagged_stories' => 'récit(s) sur ce thème',
    'all_tags' => 'Tous les thèmes',
    'no_tags' => 'Aucun thème disponible pour le moment.'
  },
  'en' => {
    'book_path' => 'one-hundred-tales-of-kansai',
    'book_title' => 'One Hundred Tales of Kansai',
    'subtitle' => 'The Blue Princess',
    'back_home' => 'Back to home',
    'back_to_toc' => 'Back to table of contents',
    'chapter' => 'Chapter',
    'narrator' => 'Narrator',
    'district' => 'District',
    'tags_index_title' => 'Tags Index',
    'tags_index_desc' => 'Explore tales by theme',
    'tagged_stories' => 'tale(s) with this tag',
    'all_tags' => 'All tags',
    'no_tags' => 'No tags available at the moment.'
  },
  'ja' => {
    'book_path' => 'kansai-hyakumonogatari',
    'book_title' => '関西百物語',
    'subtitle' => '青姫',
    'back_home' => 'ホームに戻る',
    'back_to_toc' => '目次に戻る',
    'chapter' => '第',
    'narrator' => '語り手',
    'district' => '地区',
    'tags_index_title' => 'タグ一覧',
    'tags_index_desc' => 'テーマ別に物語を探す',
    'tagged_stories' => '話',
    'all_tags' => 'すべてのタグ',
    'no_tags' => '現在利用可能なタグはありません。'
  },
  'zh' => {
    'book_path' => 'guanxi-baiwuyu',
    'book_title' => '关西百物语',
    'subtitle' => '青姬',
    'back_home' => '返回首页',
    'back_to_toc' => '返回目录',
    'chapter' => '第',
    'narrator' => '叙述者',
    'district' => '地区',
    'tags_index_title' => '标签索引',
    'tags_index_desc' => '按主题浏览故事',
    'tagged_stories' => '个故事',
    'all_tags' => '所有标签',
    'no_tags' => '目前没有可用的标签。'
  },
  'th' => {
    'book_path' => 'tamnan-roi-rueang-kansai',
    'book_title' => 'ตำนานร้อยเรื่องแห่งคันไซ',
    'subtitle' => 'เจ้าหญิงฟ้า',
    'back_home' => 'กลับหน้าแรก',
    'back_to_toc' => 'กลับสู่สารบัญ',
    'chapter' => 'บทที่',
    'narrator' => 'ผู้เล่าเรื่อง',
    'district' => 'ย่าน',
    'tags_index_title' => 'ดัชนีแท็ก',
    'tags_index_desc' => 'สำรวจเรื่องเล่าตามหัวข้อ',
    'tagged_stories' => 'เรื่อง',
    'all_tags' => 'แท็กทั้งหมด',
    'no_tags' => 'ยังไม่มีแท็กในขณะนี้'
  }
}

def parse_chapter_metadata(content)
  if content =~ /\A---\n(.*?)\n---\n/m
    metadata = YAML.load($1)
    body = content.sub(/\A---\n.*?\n---\n/m, '')
    [metadata, body]
  else
    [{}, content]
  end
end

def collect_tags_from_chapters(lang_code)
  # Structure : { slug => { 'label' => label, 'chapters' => [...] } }
  tags_data = Hash.new { |h, k| h[k] = { 'label' => k, 'chapters' => [] } }

  chapters_dir = ".book-chapters-in-markdown/#{lang_code}/chapters"
  return tags_data unless Dir.exist?(chapters_dir)

  Dir.glob("#{chapters_dir}/*.md").each do |chapter_file|
    content = File.read(chapter_file, encoding: 'utf-8')
    metadata, _ = parse_chapter_metadata(content)

    next unless metadata['chapter'] && metadata['tags']

    chapter_info = {
      'number' => metadata['chapter'].to_i,
      'title' => metadata['title'] || 'Sans titre',
      'narrator' => metadata['narrator'] || 'Inconnu',
      'district' => metadata['district'] || 'Inconnu'
    }

    # Format : { slug: "label", autre-slug: "Autre Label" }
    metadata['tags'].each do |slug, label|
      slug = slug.to_s.strip
      label = label.to_s.strip
      tags_data[slug]['label'] = label
      tags_data[slug]['chapters'] << chapter_info
    end
  end

  # Trier les chapitres de chaque tag par numéro
  tags_data.each do |slug, data|
    data['chapters'].sort_by! { |c| c['number'] }
  end

  tags_data
end

def generate_tags_index(lang_code, lang_config, tags_data)
  book_title = lang_config['book_title']
  subtitle = lang_config['subtitle']
  book_path = lang_config['book_path']

  html_content = <<~HTML
---
layout: default
title: "#{lang_config['tags_index_title']} - #{book_title}"
lang: #{lang_code}
permalink: /#{lang_code}/tags/
---

<header>
    <h1>#{book_title}</h1>
    <h2>#{subtitle}</h2>
</header>

<main>
    <article>
        <h3>#{lang_config['tags_index_title']}</h3>
        <p>#{lang_config['tags_index_desc']}</p>
  HTML

  if tags_data.empty?
    html_content += <<~HTML
        <p><em>#{lang_config['no_tags']}</em></p>
    HTML
  else
    html_content += <<~HTML

        <ul>
    HTML

    # Trier les tags par label (ordre alphabétique)
    sorted_tags = tags_data.sort_by { |slug, data| data['label'] }

    sorted_tags.each do |slug, data|
      label = data['label']
      chapter_count = data['chapters'].length
      html_content += <<~HTML
            <li><a href="/#{lang_code}/tags/#{slug}/">#{label}</a> (#{chapter_count})</li>
      HTML
    end

    html_content += <<~HTML
        </ul>
    HTML
  end

  html_content += <<~HTML
    </article>
</main>

<nav>
    <ol>
        <li><a rel="prev" href="/#{lang_code}/#{book_path}/">#{lang_config['back_to_toc']}</a></li>
    </ol>
</nav>
  HTML

  # Créer le répertoire tags si nécessaire
  tags_dir = "_#{lang_code}/tags"
  FileUtils.mkdir_p(tags_dir)

  output_file = "#{tags_dir}/index.html"
  File.write(output_file, html_content)
  puts "  Généré : #{output_file}"
end

def generate_tag_page(lang_code, lang_config, slug, tag_data)
  book_title = lang_config['book_title']
  subtitle = lang_config['subtitle']
  book_path = lang_config['book_path']
  label = tag_data['label']
  chapters = tag_data['chapters']

  html_content = <<~HTML
---
layout: default
title: "#{label} - #{book_title}"
lang: #{lang_code}
permalink: /#{lang_code}/tags/#{slug}/
---

<header>
    <h1>#{book_title}</h1>
    <h2>#{subtitle}</h2>
</header>

<main>
    <article>
        <h3>#{label}</h3>
        <p><em>#{chapters.length} #{lang_config['tagged_stories']}</em></p>

        <ol>
  HTML

  chapters.each do |chapter|
    chapter_url = "/#{lang_code}/#{book_path}/#{chapter['number']}/"
    html_content += <<~HTML
            <li>
                <a href="#{chapter_url}">#{lang_config['chapter']} #{chapter['number']}: #{chapter['title']}</a>
                — <em>#{lang_config['narrator']}: #{chapter['narrator']}, #{lang_config['district']}: #{chapter['district']}</em>
            </li>
    HTML
  end

  html_content += <<~HTML
        </ol>
    </article>
</main>

<nav>
    <ol>
        <li><a rel="prev" href="/#{lang_code}/tags/">#{lang_config['all_tags']}</a></li>
    </ol>
</nav>
  HTML

  # Créer le répertoire pour ce tag
  tag_dir = "_#{lang_code}/tags/#{slug}"
  FileUtils.mkdir_p(tag_dir)

  output_file = "#{tag_dir}/index.html"
  File.write(output_file, html_content)
  puts "  Généré : #{output_file}"
end

def generate_tags_for_language(lang_code, lang_config)
  puts "\nGénération des pages de tags pour #{lang_code}..."

  # Nettoyer l'ancien répertoire tags s'il existe
  tags_dir = "_#{lang_code}/tags"
  if Dir.exist?(tags_dir)
    FileUtils.rm_rf(tags_dir)
    puts "  Nettoyage de l'ancien répertoire : #{tags_dir}"
  end

  # Collecter tous les tags et chapitres associés
  tags_data = collect_tags_from_chapters(lang_code)

  if tags_data.empty?
    puts "  Aucun tag trouvé pour #{lang_code}"
    return
  end

  # Générer la page d'index des tags
  generate_tags_index(lang_code, lang_config, tags_data)

  # Générer une page pour chaque tag
  tags_data.each do |slug, tag_data|
    generate_tag_page(lang_code, lang_config, slug, tag_data)
  end

  puts "  #{tags_data.keys.length} tag(s) généré(s) pour #{lang_code}"
end

# Exécution pour toutes les langues
LANGUAGES.each do |lang_code, lang_config|
  generate_tags_for_language(lang_code, lang_config)
end

puts "\nDone."
