#!/usr/bin/env bash
#
# generate-icons.sh — genera el set completo de favicons + og-image a partir de un logo.
#
#   scripts/generate-icons.sh logo.svg -o public --bg '#ffffff' --og-bg '#0f172a'
#
# Entrada: SVG (preferido) o PNG con fondo transparente, idealmente >= 1024 px.
# Salida (en --out, por defecto ./public):
#   favicon.ico             16/32/48 multi-tamaño, transparente  (fallback universal, Safari)
#   favicon.svg             copia del SVG                        (sólo si la entrada es SVG)
#   apple-touch-icon.png    180x180, fondo OPACO + margen        (iOS pinta negro lo transparente)
#   icon-192.png            192x192, transparente                (manifest / Android)
#   icon-512.png            512x512, transparente                (manifest / Android / splash)
#   icon-maskable-512.png   512x512, opaco, margen de seguridad  (manifest purpose=maskable)
#   og-image.png|jpg        1200x630, fondo OPACO                (preview al compartir el link)
#
# Opciones:
#   -o, --out DIR        carpeta de salida (default: public)
#   --bg COLOR           fondo de apple-touch-icon y maskable (default: #ffffff)
#   --og-bg COLOR        fondo de og-image (default: --bg)
#   --pad N              margen % de apple-touch-icon (default: 12)
#   --og-format png|jpg  formato de og-image (default: png; usa jpg si pasa de 300 KB)
#   -f, --force          sobrescribe archivos existentes
#
# Requiere ImageMagick (magick o convert). Para SVG usa rsvg-convert si existe (mejor calidad).
# Compatible con bash 3.2 (macOS).
set -euo pipefail

usage() { sed -n '3,25p' "$0" | sed -E 's/^# ?//'; }

SRC=""; OUT="public"; BG="#ffffff"; OG_BG=""; PAD=12; OG_FORMAT="png"; FORCE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--out)    OUT="$2"; shift 2 ;;
    --bg)        BG="$2"; shift 2 ;;
    --og-bg)     OG_BG="$2"; shift 2 ;;
    --pad)       PAD="$2"; shift 2 ;;
    --og-format) OG_FORMAT="$2"; shift 2 ;;
    -f|--force)  FORCE=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    -*)          echo "Opción desconocida: $1" >&2; usage >&2; exit 1 ;;
    *)           SRC="$1"; shift ;;
  esac
done
[[ -n "$SRC" ]] || { usage >&2; exit 1; }
[[ -f "$SRC" ]] || { echo "No existe: $SRC" >&2; exit 1; }
OG_BG="${OG_BG:-$BG}"
case "$OG_FORMAT" in png|jpg|jpeg) ;; *) echo "--og-format debe ser png o jpg" >&2; exit 1 ;; esac

if command -v magick >/dev/null 2>&1; then IM=magick; IDENT="magick identify"
elif command -v convert >/dev/null 2>&1; then IM=convert; IDENT=identify
else
  echo "Falta ImageMagick. macOS: brew install imagemagick · Debian: apt install imagemagick librsvg2-bin" >&2
  exit 1
fi

ext=$(printf '%s' "${SRC##*.}" | tr '[:upper:]' '[:lower:]')
OUTPUTS="favicon.ico apple-touch-icon.png icon-192.png icon-512.png icon-maskable-512.png og-image.$OG_FORMAT"
[[ "$ext" == "svg" ]] && OUTPUTS="favicon.svg $OUTPUTS"

# No pisar iconos hechos a mano sin que el usuario lo sepa
if (( ! FORCE )); then
  existing=""
  for f in $OUTPUTS; do [[ -e "$OUT/$f" ]] && existing="$existing $f"; done
  if [[ -n "$existing" ]]; then
    echo "Ya existen en $OUT/:$existing" >&2
    echo "Usa --force para sobrescribirlos." >&2
    exit 1
  fi
fi

mkdir -p "$OUT"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
MASTER="$TMP/master.png"

# 1) Máster 1024x1024 transparente: rasteriza, recorta márgenes vacíos, ajusta al cuadrado y centra
if [[ "$ext" == "svg" ]]; then
  if command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert -w 2048 -h 2048 --keep-aspect-ratio "$SRC" -o "$TMP/raster.png"
  else
    "$IM" -background none -density 600 "$SRC" -resize 2048x2048 "$TMP/raster.png"
  fi
  cp "$SRC" "$OUT/favicon.svg"
else
  "$IM" "$SRC" -background none "$TMP/raster.png"
  dims=$($IDENT -format '%w %h' "$TMP/raster.png"); w=${dims% *}; h=${dims#* }
  if (( w < 512 || h < 512 )); then
    echo "AVISO: el PNG mide ${w}x${h}; con menos de 512 px los iconos grandes saldrán borrosos. Pide el SVG o un PNG mayor." >&2
  fi
fi
"$IM" "$TMP/raster.png" -trim +repage -background none \
  -resize 1024x1024 -gravity center -extent 1024x1024 "$MASTER"

# 2) Icono cuadrado: icon SIZE OUT BG PAD%
icon() {
  local size=$1 out=$2 bg=$3 pad=$4
  local inner=$(( size * (100 - 2 * pad) / 100 ))
  "$IM" -size "${size}x${size}" "xc:${bg}" \
    \( "$MASTER" -resize "${inner}x${inner}" \) \
    -gravity center -composite -strip "$out"
}

icon 192 "$OUT/icon-192.png"          none  0
icon 512 "$OUT/icon-512.png"          none  0
icon 512 "$OUT/icon-maskable-512.png" "$BG" 20      # zona segura maskable: círculo del 80 %
icon 180 "$OUT/apple-touch-icon.png"  "$BG" "$PAD"

# 3) favicon.ico multi-tamaño. Sin margen: a 16 px cualquier margen se come el logo
for s in 16 32 48; do icon "$s" "$TMP/fav-$s.png" none 0; done
"$IM" "$TMP/fav-16.png" "$TMP/fav-32.png" "$TMP/fav-48.png" "$OUT/favicon.ico"

# 4) og-image 1200x630: logo centrado ocupando ~55 % de alto, fondo opaco (los clientes en modo
#    oscuro pintan negro lo transparente y el logo desaparece)
OG="$OUT/og-image.$OG_FORMAT"
QUALITY=()
[[ "$OG_FORMAT" != "png" ]] && QUALITY=(-quality 88)
"$IM" -size 1200x630 "xc:${OG_BG}" \
  \( "$MASTER" -trim +repage -resize 720x346 \) \
  -gravity center -composite -strip ${QUALITY[@]+"${QUALITY[@]}"} "$OG"

# 5) Reporte
size_of() { wc -c < "$1" | tr -d ' '; }
echo
echo "Generado en $OUT/:"
for f in $OUTPUTS; do
  dims=$($IDENT -format '%wx%h' "$OUT/$f[0]" 2>/dev/null || true)
  printf '  %-24s %8s bytes  %s\n' "$f" "$(size_of "$OUT/$f")" "$dims"
done

og_bytes=$(size_of "$OG")
if (( og_bytes > 300000 )); then
  echo
  echo "AVISO: og-image pesa $(( og_bytes / 1024 )) KB (> 300 KB): WhatsApp puede no mostrarla." >&2
  echo "       Regenera con --og-format jpg, o simplifica el logo." >&2
fi
