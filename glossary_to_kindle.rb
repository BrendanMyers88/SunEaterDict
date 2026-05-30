#!/usr/bin/env ruby
require "json"
require "cgi"
require "fileutils"

TITLE = "Sun Eater Glossary"
AUTHOR = "Christopher Ruocchio"
LANG = "en"
BOOK_ID = "sun-eater-glossary"

INPUT = File.expand_path("glossary.json", __dir__)
OUTPUT_DIR = File.expand_path("kindle_dictionary", __dir__)

FileUtils.mkdir_p(OUTPUT_DIR)

entries = JSON.parse(File.read(INPUT))

def pluralize_term(term)
  return "#{term[0...-1]}ies" if term.match?(/[^aeiou]y$/i)
  return "#{term}es" if term.match?(/(?:s|x|z|ch|sh)$/i)

  "#{term}s"
end

def possessive_forms(term)
  [
    "#{term}'s",
    "#{term}’s"
  ]
end

def lookup_forms_for(term)
  forms = [term]

  # Common Kindle lookup failures:
  # - singular glossary entry selected as plural in the book
  # - straight/apostrophe curly apostrophe mismatch
  # - possessive selections
  forms << pluralize_term(term)
  forms.concat(possessive_forms(term))

  # If the term is multi-word, include useful phrase variants.
  if term.include?(" ")
    words = term.split(/\s+/)

    forms << words.join(" ")
    forms << words.join("-")
    forms << words.join("’")
    forms << words.join("'")

    # Also support plural/possessive phrase selections.
    forms << pluralize_term(term)
    forms.concat(possessive_forms(term))
  end

  forms.compact.map(&:strip).reject(&:empty?).uniq
end

content_path = File.join(OUTPUT_DIR, "content.html")
File.open(content_path, "w") do |f|
  f.puts <<~HEAD
    <?xml version="1.0" encoding="utf-8"?>
    <html xmlns:math="http://exslt.org/math"
          xmlns:svg="http://www.w3.org/2000/svg"
          xmlns:tl="https://kindlegen.s3.amazonaws.com/AmazonKindlePublishingGuidelines.pdf"
          xmlns:saxon="http://saxon.sf.net/"
          xmlns:xs="http://www.w3.org/2001/XMLSchema"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns:cx="https://kindlegen.s3.amazonaws.com/AmazonKindlePublishingGuidelines.pdf"
          xmlns:dc="http://purl.org/dc/elements/1.1/"
          xmlns:mbp="https://kindlegen.s3.amazonaws.com/AmazonKindlePublishingGuidelines.pdf"
          xmlns:mmc="https://kindlegen.s3.amazonaws.com/AmazonKindlePublishingGuidelines.pdf"
          xmlns:idx="https://kindlegen.s3.amazonaws.com/AmazonKindlePublishingGuidelines.pdf">
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
      <style>
        h5 { font-size: 1em; margin: 0 0 0.25em 0; }
        p  { margin: 0 0 0.5em 0; }
      </style>
    </head>
    <body>
      <mbp:frameset>
  HEAD

  entries.sort_by { |term, _| term.downcase }.each_with_index do |(term, definition), i|
    escaped_term = CGI.escapeHTML(term)
    escaped_definition = CGI.escapeHTML(definition)
    lookup_forms = lookup_forms_for(term)

    f.puts <<~ENTRY
      <idx:entry name="default" scriptable="yes" spell="yes">
        <idx:short>
          <a id="entry-#{i}"></a>
          <idx:orth value="#{escaped_term}">
            <idx:infl>
    ENTRY

    lookup_forms.each do |form|
      f.puts %(          <idx:iform value="#{CGI.escapeHTML(form)}"/>)
    end

    f.puts <<~ENTRY
            </idx:infl>
            <h5>#{escaped_term}</h5>
          </idx:orth>
          <p>#{escaped_definition}</p>
        </idx:short>
      </idx:entry>
      <hr/>
    ENTRY
  end

  f.puts <<~TAIL
      </mbp:frameset>
    </body>
    </html>
  TAIL
end

opf_path = File.join(OUTPUT_DIR, "dictionary.opf")
File.write(opf_path, <<~OPF)
  <?xml version="1.0" encoding="utf-8"?>
  <package version="2.0"
           xmlns="http://www.idpf.org/2007/opf"
           unique-identifier="BookId">
    <metadata xmlns:dc="http://purl.org/dc/elements/1.1/"
              xmlns:opf="http://www.idpf.org/2007/opf">
      <dc:title>#{CGI.escapeHTML(TITLE)}</dc:title>
      <dc:creator opf:role="aut">#{CGI.escapeHTML(AUTHOR)}</dc:creator>
      <dc:language>#{LANG}</dc:language>
      <dc:identifier id="BookId" opf:scheme="uuid">#{BOOK_ID}</dc:identifier>
      <meta name="primary-writing-mode" content="horizontal-lr"/>
      <meta name="catalog_index_type" content="CL" />
      <x-metadata>
        <DictionaryInLanguage>#{LANG}</DictionaryInLanguage>
        <DictionaryOutLanguage>#{LANG}</DictionaryOutLanguage>
        <DefaultLookupIndex>default</DefaultLookupIndex>
      </x-metadata>
    </metadata>
    <manifest>
      <item id="content" href="content.html" media-type="application/xhtml+xml"/>
    </manifest>
    <spine>
      <itemref idref="content"/>
    </spine>
    <guide>
      <reference type="index" title="Index" href="content.html"/>
    </guide>
  </package>
OPF

puts "Wrote #{entries.size} entries -> #{content_path}"
puts "Wrote OPF              -> #{opf_path}"
puts ""
puts "Next: build the .mobi with Kindle Previewer 3:"
puts "  /Applications/Kindle\\ Previewer\\ 3.app/Contents/MacOS/lib/fc/bin/kindlegen #{opf_path}"
puts "Or open #{opf_path} in Kindle Previewer 3 and export."
