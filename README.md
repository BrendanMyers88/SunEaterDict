# Sun Eater Kindle Dictionary

*AI was used in making this project*

A small Ruby project for building a Kindle-compatible dictionary from a JSON glossary of *Sun Eater* terms.

The source glossary lives in `glossary.json`. The generated Kindle dictionary files live in `kindle_dictionary/`.

## Requirements

### Ruby

This project uses Ruby.

Recommended version:

```bash
ruby 3.4.3
```

If using `rbenv`:

```bash
rbenv install 3.4.3
rbenv local 3.4.3
```

The script uses Ruby standard libraries only, so there is no required `bundle install` step.

### Kindle Tools

To build the final `.mobi` dictionary file, you need Amazon Kindle tooling.

The project expects `kindlegen`, which is commonly bundled with **Kindle Previewer 3**.

On macOS, it is often available at:

```bash
/Applications/Kindle\ Previewer\ 3.app/Contents/MacOS/lib/fc/bin/kindlegen
```

If your `kindlegen` binary is somewhere else, use that path instead.

## Files

- `glossary.json` — the editable source glossary.
- `glossary_to_kindle.rb` — generates Kindle dictionary source files.
- `kindle_dictionary/content.html` — generated dictionary HTML.
- `kindle_dictionary/dictionary.opf` — generated Kindle package metadata.
- `kindle_dictionary/dictionary.mobi` — compiled Kindle dictionary file.

## Updating the Dictionary

### 1. Edit `glossary.json`

Add, remove, or update glossary entries in `glossary.json`.

Entries should be JSON key/value pairs:

```json
{
  "Term": "Definition text."
}
```

Example:

```json
{
  "Cielcin": "Spacefaring alien species. Humanoid and carnivorous.",
  "Sollan Empire": "The largest and oldest single polity in human-controlled space."
}
```

Keep the file valid JSON:

- Use double quotes around keys and values.
- Separate entries with commas.
- Do not add a trailing comma after the final entry.
- Escape embedded double quotes as `\"`.

### 2. Regenerate Kindle Source Files

From the project root, run:

```bash
ruby glossary_to_kindle.rb
```

This regenerates:

```text
kindle_dictionary/content.html
kindle_dictionary/dictionary.opf
```

The generator sorts entries alphabetically and adds extra lookup forms for common Kindle lookup cases, including plural and possessive variants.

### 3. Build the `.mobi`

Run `kindlegen` against the generated OPF file:

```bash
/Applications/Kindle\ Previewer\ 3.app/Contents/MacOS/lib/fc/bin/kindlegen kindle_dictionary/dictionary.opf
```

If you have kinglegen in your path, simply run:
```bash
kindlegen kindle_dictionary/dictionary.opf
```

This creates or updates the compiled Kindle dictionary in `kindle_dictionary/`.

Alternatively, open this file in Kindle Previewer 3:

```text
kindle_dictionary/dictionary.opf
```

Then export/build the Kindle file from the app.

## Common Workflow

```bash
ruby glossary_to_kindle.rb
kindlegen kindle_dictionary/dictionary.opf
```

Then copy the generated `.mobi` file to your Kindle.

## Installing on a Kindle

1. Connect the Kindle by USB.
2. Copy `kindle_dictionary/dictionary.mobi` to the Kindle’s `documents/dictionaries` folder.
3. Eject the Kindle.
4. On the Kindle, select the Sun Eater glossary as a dictionary if needed.

Exact dictionary selection steps vary by Kindle model and firmware version.

## Troubleshooting

### Ruby is missing

If `ruby` is not found, install Ruby or configure your Ruby version manager.

With `rbenv`, check:

```bash
rbenv versions
ruby --version
```

### JSON parse errors

If generation fails while reading `glossary.json`, validate the JSON syntax.

Common causes include:

- Missing commas between entries.
- Trailing comma after the final entry.
- Unescaped double quotes inside definitions.
- Mismatched braces.

### `kindlegen` is missing

Use the full path to `kindlegen`, or add its directory to your `PATH`.

Example macOS path:

```bash
/Applications/Kindle\ Previewer\ 3.app/Contents/MacOS/lib/fc/bin/kindlegen
```

### Dictionary builds but lookup does not work

Make sure the `.mobi` was built from:

```text
kindle_dictionary/dictionary.opf
```

Also confirm that your Kindle has selected the Sun Eater glossary as the dictionary for English lookup.

## Notes

Generated files in `kindle_dictionary/` should be regenerated after every change to `glossary.json`.

The `.mobi` file should be rebuilt after regenerating `content.html` and `dictionary.opf`.

I like to rename the `.mobi` file so it's unique in the Kindle's `documents/dictionaries` directory, ie `SunEater.mobi`

Multi-word selection doesn't work unfortunately, if you have a way to get it working feel free to make a PR!
