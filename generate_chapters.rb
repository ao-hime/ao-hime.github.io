#!/usr/bin/env ruby
# Script pour générer les fichiers HTML des chapitres à partir des fichiers Markdown

require 'fileutils'
require 'yaml'

# Configuration des langues et des chemins
LANGUAGES = {
  'fr' => {
    'book_path' => 'cent-histoires-de-la-region-du-kansai',
    'book_title' => 'Cent Histoires de la Région du Kansai',
    'back_to_toc' => '← Retour à la table des matières',
    'previous_chapter' => '← Chapitre précédent',
    'next_chapter' => 'Chapitre suivant →',
    'narrator' => 'Narrateur',
    'district' => 'District',
    'chapter' => 'Chapitre',
    'introduction' => 'Introduction',
    'conclusion' => 'Conclusion',
    'table_of_contents' => 'Table des matières',
    'intro_path' => 'introduction',
    'conclusion_path' => 'conclusion'
  },
  'en' => {
    'book_path' => 'one-hundred-tales-of-kansai',
    'book_title' => 'One Hundred Tales of Kansai',
    'back_to_toc' => '← Back to table of contents',
    'previous_chapter' => '← Previous chapter',
    'next_chapter' => 'Next chapter →',
    'narrator' => 'Narrator',
    'district' => 'District',
    'chapter' => 'Chapter',
    'introduction' => 'Introduction',
    'conclusion' => 'Conclusion',
    'table_of_contents' => 'Table of Contents',
    'intro_path' => 'introduction',
    'conclusion_path' => 'conclusion'
  },
  'ja' => {
    'book_path' => 'kansai-hyakumonogatari',
    'book_title' => '関西百物語',
    'back_to_toc' => '← 目次に戻る',
    'previous_chapter' => '← 前の話',
    'next_chapter' => '次の話 →',
    'narrator' => '語り手',
    'district' => '地区',
    'chapter' => '第',
    'introduction' => '序章',
    'conclusion' => '終章',
    'table_of_contents' => '目次',
    'intro_path' => 'josho',
    'conclusion_path' => 'shusho'
  },
  'zh' => {
    'book_path' => 'guanxi-baiwuyu',
    'book_title' => '关西百物语',
    'back_to_toc' => '← 返回目录',
    'previous_chapter' => '← 上一章',
    'next_chapter' => '下一章 →',
    'narrator' => '叙述者',
    'district' => '地区',
    'chapter' => '第',
    'introduction' => '序言',
    'conclusion' => '结语',
    'table_of_contents' => '目录',
    'intro_path' => 'xuyan',
    'conclusion_path' => 'jieyu'
  },
  'th' => {
    'book_path' => 'tamnan-roi-rueang-kansai',
    'book_title' => 'ตำนานร้อยเรื่องแห่งคันไซ',
    'back_to_toc' => '← กลับไปยังสารบัญ',
    'previous_chapter' => '← ตอนก่อนหน้า',
    'next_chapter' => 'ตอนถัดไป →',
    'narrator' => 'ผู้เล่าเรื่อง',
    'district' => 'ย่าน',
    'chapter' => 'บทที่',
    'introduction' => 'บทนำ',
    'conclusion' => 'บทส่งท้าย',
    'table_of_contents' => 'สารบัญ',
    'intro_path' => 'botnam',
    'conclusion_path' => 'botsongthai'
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

def convert_markdown_to_html(text)
  # Conversion basique du Markdown vers HTML
  text = text.gsub(/^# (.+)$/, '<h2>\1</h2>')
             .gsub(/^\*(.+)\*$/, '<p><em>\1</em></p>')
             .gsub(/\*([^*]+)\*/, '<em>\1</em>')
             .gsub(/^(.+)$/) { |line| line.strip.empty? ? '' : "<p>#{line.strip}</p>" }
             .gsub(/<p><p>/, '<p>')
             .gsub(/<\/p><\/p>/, '</p>')
             .gsub(/<p><h2>/, '<h2>')
             .gsub(/<\/h2><\/p>/, '</h2>')
             .gsub(/<p><em><\/p>/, '<em>')
             .gsub(/<p><\/em><\/p>/, '</em>')

  text
end

def get_chapters_info(lang_code)
  chapters_dir = ".book-chapters-in-markdown/#{lang_code}/chapters"
  chapters = []

  return chapters unless Dir.exist?(chapters_dir)

  Dir.glob("#{chapters_dir}/*.md").each do |chapter_file|
    content = File.read(chapter_file, encoding: 'utf-8')
    metadata, _ = parse_chapter_metadata(content)

    if metadata['chapter']
      chapters << {
        'file' => chapter_file,
        'number' => metadata['chapter'].to_i,
        'title' => metadata['title'] || 'Sans titre',
        'narrator' => metadata['narrator'] || 'Inconnu',
        'district' => metadata['district'] || 'Inconnu'
      }
    end
  end

  chapters.sort_by { |c| c['number'] }
end

def generate_chapter_html(chapter_info, prev_chapter, next_chapter, lang_code, lang_config)
  content = File.read(chapter_info['file'], encoding: 'utf-8')
  metadata, body = parse_chapter_metadata(content)

  chapter_num = metadata['chapter'] || 0
  title = metadata['title'] || 'Sans titre'
  narrator = metadata['narrator'] || 'Inconnu'
  district = metadata['district'] || 'Inconnu'
  organizer_intro = metadata['organizer_intro'] || ''

  book_title = lang_config['book_title']
  book_path = lang_config['book_path']

  html_body = convert_markdown_to_html(body)

  html_content = <<~HTML
---
layout: default
title: "#{title} - #{book_title}"
lang: #{lang_code}
permalink: /#{lang_code}/#{book_path}/#{chapter_num}/
---

<header>
    <h1>#{book_title}</h1>
    <p><a href="/#{lang_code}/#{book_path}/">#{lang_config['back_to_toc']}</a></p>
</header>

<main>
    <article>
        <h2>#{lang_config['chapter']} #{chapter_num} : #{title}</h2>
        <p><em>#{lang_config['narrator']} : #{narrator} - #{lang_config['district']} : #{district}</em></p>
  HTML

  if !organizer_intro.empty?
    html_content += <<~HTML

        <blockquote>
#{convert_markdown_to_html(organizer_intro).gsub(/^/, '            ')}
        </blockquote>
    HTML
  end

  html_content += <<~HTML

#{html_body.gsub(/^/, '        ')}
    </article>

    <nav>
  HTML

  if prev_chapter
    html_content += <<~HTML
        <p><a href="/#{lang_code}/#{book_path}/#{prev_chapter['number']}/">#{lang_config['previous_chapter']}</a></p>
    HTML
  end

  if next_chapter
    html_content += <<~HTML
        <p><a href="/#{lang_code}/#{book_path}/#{next_chapter['number']}/">#{lang_config['next_chapter']}</a></p>
    HTML
  end

  html_content += <<~HTML
    </nav>
</main>
  HTML

  html_content
end

def generate_introduction_page(lang_code, lang_config)
  intro_file = ".book-chapters-in-markdown/#{lang_code}/introduction.md"
  return nil unless File.exist?(intro_file)

  content = File.read(intro_file, encoding: 'utf-8')
  metadata, body = parse_chapter_metadata(content)

  book_title = lang_config['book_title']
  book_path = lang_config['book_path']
  intro_path = lang_config['intro_path']

  html_body = convert_markdown_to_html(body)

  html_content = <<~HTML
---
layout: default
title: "#{lang_config['introduction']} - #{book_title}"
lang: #{lang_code}
permalink: /#{lang_code}/#{intro_path}/
---

<header>
    <h1>#{book_title}</h1>
    <p><a href="/#{lang_code}/#{book_path}/">#{lang_config['back_to_toc']}</a></p>
</header>

<main>
    <article>
        <h2>#{lang_config['introduction']}</h2>
#{html_body.gsub(/^/, '        ')}
    </article>

    <nav>
        <p><a href="/#{lang_code}/#{book_path}/">#{lang_config['table_of_contents']} →</a></p>
    </nav>
</main>
  HTML

  output_file = "_#{lang_code}/#{intro_path}.html"
  File.write(output_file, html_content)
  puts "  Généré : #{output_file}"
end

def generate_conclusion_page(lang_code, lang_config)
  conclusion_file = ".book-chapters-in-markdown/#{lang_code}/conclusion.md"
  return nil unless File.exist?(conclusion_file)

  content = File.read(conclusion_file, encoding: 'utf-8')
  metadata, body = parse_chapter_metadata(content)

  book_title = lang_config['book_title']
  book_path = lang_config['book_path']
  conclusion_path = lang_config['conclusion_path']

  html_body = convert_markdown_to_html(body)

  html_content = <<~HTML
---
layout: default
title: "#{lang_config['conclusion']} - #{book_title}"
lang: #{lang_code}
permalink: /#{lang_code}/#{conclusion_path}/
---

<header>
    <h1>#{book_title}</h1>
    <p><a href="/#{lang_code}/#{book_path}/">#{lang_config['back_to_toc']}</a></p>
</header>

<main>
    <article>
        <h2>#{lang_config['conclusion']}</h2>
#{html_body.gsub(/^/, '        ')}
    </article>

    <nav>
        <p><a href="/#{lang_code}/#{book_path}/">#{lang_config['back_to_toc']}</a></p>
    </nav>
</main>
  HTML

  output_file = "_#{lang_code}/#{conclusion_path}.html"
  File.write(output_file, html_content)
  puts "  Généré : #{output_file}"
end

def generate_book_index(lang_code, lang_config, chapters)
  book_title = lang_config['book_title']
  book_path = lang_config['book_path']
  intro_path = lang_config['intro_path']
  conclusion_path = lang_config['conclusion_path']

  has_intro = File.exist?(".book-chapters-in-markdown/#{lang_code}/introduction.md")
  has_conclusion = File.exist?(".book-chapters-in-markdown/#{lang_code}/conclusion.md")

  back_label = case lang_code
               when 'fr' then 'Retour'
               when 'en' then 'Back'
               when 'ja' then '戻る'
               when 'zh' then '返回'
               when 'th' then 'ย้อนกลับ'
               else 'Back'
               end

  html_content = <<~HTML
---
layout: default
title: "#{book_title} - #{lang_config['table_of_contents']}"
lang: #{lang_code}
permalink: /#{lang_code}/#{book_path}/
---

<header>
    <h1>#{book_title}</h1>
    <p><a href="/#{lang_code}/">← #{back_label}</a></p>
</header>

<main>
    <h2>#{lang_config['table_of_contents']}</h2>

    <nav>
        <ol>
  HTML

  if has_intro
    html_content += <<~HTML
            <li><a href="/#{lang_code}/#{intro_path}/">#{lang_config['introduction']}</a></li>
    HTML
  end

  chapters.each do |chapter|
    html_content += <<~HTML
            <li><a href="/#{lang_code}/#{book_path}/#{chapter['number']}/">#{lang_config['chapter']} #{chapter['number']} : #{chapter['title']}</a></li>
    HTML
  end

  if has_conclusion
    html_content += <<~HTML
            <li><a href="/#{lang_code}/#{conclusion_path}/">#{lang_config['conclusion']}</a></li>
    HTML
  end

  html_content += <<~HTML
        </ol>
    </nav>
</main>
  HTML

  output_file = "_#{lang_code}/#{book_path}.html"
  File.write(output_file, html_content)
  puts "  Généré : #{output_file}"
end

def generate_language_index(lang_code, lang_config)
  book_title = lang_config['book_title']
  book_path = lang_config['book_path']

  texts = {
    'fr' => {
      'subtitle' => 'La Princesse Bleue',
      'about_title' => 'À propos du livre',
      'about_text' => "Dans un petit temple de Namba, à Osaka, cent passionnés d'ōgi se retrouvent pour une soirée extraordinaire. Ils participent au hyakumonogatari kaidankai – une tradition japonaise où chacun raconte une histoire étrange avant d'éteindre sa bougie.",
      'about_text2' => "Un recueil de témoignages troublants qui vous plongera dans les mystères du Kansai moderne.",
      'buy_title' => 'Acheter le livre',
      'read_online_title' => 'Lire en ligne',
      'read_online_text' => 'Accéder à la version web gratuite',
      'back_home' => "Retour à l'accueil",
      'coming_soon' => 'à venir'
    },
    'en' => {
      'subtitle' => 'The Blue Princess',
      'about_title' => 'About the Book',
      'about_text' => "In a small temple in Namba, Osaka, one hundred ōgi enthusiasts gather for an extraordinary evening. They will participate in the hyakumonogatari kaidankai – an old Japanese tradition where each person tells a strange story before extinguishing their candle.",
      'about_text2' => "A collection of disturbing testimonies that will immerse you in the mysteries of modern Kansai.",
      'buy_title' => 'Buy the Book',
      'read_online_title' => 'Read Online',
      'read_online_text' => 'Access the free web version',
      'back_home' => "Back to home",
      'coming_soon' => 'coming soon'
    },
    'ja' => {
      'subtitle' => '青姫',
      'about_title' => '本について',
      'about_text' => "大阪・難波の小さな寺院に、百人の王棋（おうぎ）愛好家が集まった。彼らは「百物語怪談会」に参加するのだ――それぞれが不思議な話を語り、蝋燭を消していく古い日本の伝統である。",
      'about_text2' => "現代の関西の謎に浸る不穏な証言集。",
      'buy_title' => '本を購入',
      'read_online_title' => 'オンラインで読む',
      'read_online_text' => '無料ウェブ版にアクセス',
      'back_home' => "ホームに戻る",
      'coming_soon' => '近日公開'
    },
    'zh' => {
      'subtitle' => '青姬',
      'about_title' => '关于本书',
      'about_text' => '在大阪难波的一座小寺庙里，一百位王棋爱好者聚集在一起，准备度过一个不同寻常的夜晚。他们将参加"百物语怪谈会"——一个古老的日本传统，每个人讲述一个奇异的故事后吹灭自己的蜡烛。',
      'about_text2' => "一本让您沉浸在现代关西神秘之中的诡异见证集。",
      'buy_title' => '购买本书',
      'read_online_title' => '在线阅读',
      'read_online_text' => '访问免费网络版',
      'back_home' => "返回首页",
      'coming_soon' => '即将推出'
    },
    'th' => {
      'subtitle' => 'เจ้าหญิงฟ้า',
      'about_title' => 'เกี่ยวกับหนังสือ',
      'about_text' => 'ในวัดเล็ก ๆ ย่านนัมบะ เมืองโอซาก้า ผู้คนที่มีความเกี่ยวพันกับเกม ōgi มารวมตัวกันเพื่อค่ำคืนที่ไม่เหมือนทุกครั้ง พวกเขาจะเข้าร่วมพิธี hyakumonogatari kaidankai – ประเพณีเก่าแก่ของญี่ปุ่น ที่แต่ละคนผลัดกันเล่าเรื่องลึกลับ ก่อนจะดับเทียนของตนลง',
      'about_text2' => 'รวมคำบอกเล่าชวนขนลุกที่จะพาคุณดำดิ่งสู่ปริศนาแห่งคันไซร่วมสมัย',
      'buy_title' => 'สั่งซื้อหนังสือ',
      'read_online_title' => 'อ่านออนไลน์',
      'read_online_text' => 'เข้าถึงฉบับเว็บฟรี',
      'back_home' => 'กลับหน้าแรก',
      'coming_soon' => 'เร็ว ๆ นี้'
    }
  }

  lang_texts = texts[lang_code]

  html_content = <<~HTML
---
layout: default
title: "#{book_title} – #{lang_texts['subtitle']}"
lang: #{lang_code}
permalink: /#{lang_code}/
---

<header>
    <h1>#{book_title}</h1>
    <h2>#{lang_texts['subtitle']}</h2>
</header>

<main>
    <section>
        <h3>#{lang_texts['about_title']}</h3>
        <p>#{lang_texts['about_text']}</p>
        <p>#{lang_texts['about_text2']}</p>
    </section>

    <section>
        <h3>#{lang_texts['buy_title']}</h3>
        <ul>
            <li><a href="#">Amazon (#{lang_texts['coming_soon']})</a></li>
            <li><a href="#">Kobo (#{lang_texts['coming_soon']})</a></li>
            <li><a href="#">Apple Books (#{lang_texts['coming_soon']})</a></li>
        </ul>
    </section>

    <section>
        <h3>#{lang_texts['read_online_title']}</h3>
        <p><a href="/#{lang_code}/#{book_path}/">#{lang_texts['read_online_text']}</a></p>
    </section>

    <nav>
        <p><a href="/">#{lang_texts['back_home']}</a></p>
    </nav>
</main>
  HTML

  output_file = "_#{lang_code}/index.html"
  File.write(output_file, html_content)
  puts "  Généré : #{output_file}"
end

def generate_chapters_for_language(lang_code, lang_config)
  puts "\nGénération des chapitres pour #{lang_code}..."

  FileUtils.mkdir_p("_#{lang_code}")

  generate_language_index(lang_code, lang_config)

  chapters = get_chapters_info(lang_code)

  if chapters.empty?
    puts "  Aucun chapitre trouvé dans #{lang_code}/chapters/"
  else
    book_path = lang_config['book_path']

    chapters.each_with_index do |chapter, index|
      prev_chapter = index > 0 ? chapters[index - 1] : nil
      next_chapter = index < chapters.length - 1 ? chapters[index + 1] : nil

      html_content = generate_chapter_html(chapter, prev_chapter, next_chapter, lang_code, lang_config)

      output_file = "_#{lang_code}/#{book_path}-#{chapter['number']}.html"
      File.write(output_file, html_content)
      puts "  Généré : #{output_file}"
    end

    puts "  #{chapters.length} chapitres générés pour #{lang_code}"
  end

  generate_introduction_page(lang_code, lang_config)
  generate_conclusion_page(lang_code, lang_config)
  generate_book_index(lang_code, lang_config, chapters)
end

LANGUAGES.each do |lang_code, lang_config|
  generate_chapters_for_language(lang_code, lang_config)
end

puts "\nDone."
