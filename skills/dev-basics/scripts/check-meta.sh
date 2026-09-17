#!/usr/bin/env bash
#
# check-meta.sh — comprueba favicon, metatags y og:image de una URL pública tal y como los
# vería el crawler de Facebook/WhatsApp (el más estricto de todos).
#
#   scripts/check-meta.sh https://ejemplo.com
#
# Sale con 1 si hay fallos (✘). Los avisos (⚠) no bloquean.
# Compatible con bash 3.2 (macOS). Requiere curl; usa ImageMagick si está para medir la imagen.
set -uo pipefail

URL="${1:-}"
[[ -n "$URL" ]] || { echo "uso: $0 https://dominio" >&2; exit 1; }

UA="facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)"
CURL=(curl -sL -A "$UA" --max-time 20)

fail=0
ok()   { printf '  ✔ %s\n' "$*"; }
warn() { printf '  ⚠ %s\n' "$*"; }
bad()  { printf '  ✘ %s\n' "$*"; fail=1; }

HTML=$(mktemp); FLAT=$(mktemp); IMG=$(mktemp)
trap 'rm -f "$HTML" "$FLAT" "$IMG"' EXIT

# ---------- página ----------
code=$("${CURL[@]}" -o "$HTML" -w '%{http_code}' "$URL")
final=$("${CURL[@]}" -o /dev/null -w '%{url_effective}' "$URL")
tr '\n\r' '  ' < "$HTML" > "$FLAT"      # los tags pueden ocupar varias líneas
origin=$(printf '%s' "$final" | sed -E 's#^(https?://[^/]+).*#\1#')

echo "Página: $URL"
if [[ "$code" == "200" ]]; then ok "HTTP $code"
else bad "HTTP $code — el crawler no verá nada (¿auth, staging protegido, bot bloqueado por WAF?)"; fi
if [[ "$final" != "$URL" && "$final" != "$URL/" ]]; then
  warn "redirige a $final — los tags deben estar en la URL final y og:url debe apuntar a ella"
fi
if grep -qiE 'name=["'"'"']robots["'"'"'][^>]*noindex' "$FLAT"; then
  warn "meta robots noindex presente (no afecta al preview, pero sí a buscadores)"
fi

# meta KEY → content (acepta property= o name=, comillas dobles o simples, cualquier orden)
meta() {
  grep -oiE '<meta[^>]+>' "$FLAT" \
    | grep -iE "(property|name)=[\"']$1[\"']" \
    | head -1 \
    | sed -nE "s/.*content=\"([^\"]*)\".*/\1/p; s/.*content='([^']*)'.*/\1/p"
}
link_href() {
  grep -oiE '<link[^>]+>' "$FLAT" \
    | grep -iE "rel=[\"']$1[\"']" \
    | head -1 \
    | sed -nE "s/.*href=\"([^\"]*)\".*/\1/p; s/.*href='([^']*)'.*/\1/p"
}
abs() { case "$1" in http*) printf '%s' "$1" ;; /*) printf '%s%s' "$origin" "$1" ;; *) printf '%s/%s' "$origin" "$1" ;; esac; }

# ---------- metatags ----------
echo; echo "Metatags:"
title=$(sed -nE 's/.*<title[^>]*>([^<]*)<\/title>.*/\1/p' "$FLAT" | head -1)
[[ -n "$title" ]] && ok "title: $title" || bad "sin <title>"

desc=$(meta description)
if [[ -n "$desc" ]]; then
  (( ${#desc} <= 160 )) && ok "description (${#desc} chars)" || warn "description tiene ${#desc} chars; se corta a ~160"
else warn "sin meta description"; fi

for k in og:title og:description og:url og:type; do
  v=$(meta "$k"); [[ -n "$v" ]] && ok "$k: $v" || bad "falta $k"
done
tc=$(meta twitter:card)
[[ "$tc" == "summary_large_image" ]] && ok "twitter:card: $tc" || warn "twitter:card = '${tc:-∅}' (X necesita summary_large_image para la tarjeta grande)"

ogurl=$(meta og:url)
if [[ -n "$ogurl" && "$ogurl" != "$final" && "$ogurl/" != "$final" && "$ogurl" != "${final%/}" ]]; then
  warn "og:url ($ogurl) no coincide con la URL final ($final)"
fi

# WhatsApp sólo lee los primeros ~300 KB del HTML
pos=$(grep -boiE "property=[\"']og:" "$HTML" | head -1 | cut -d: -f1)
if [[ -n "$pos" ]]; then
  (( pos < 300000 )) && ok "og:* empieza en el byte $pos" || bad "og:* empieza en el byte $pos (> 300 KB): WhatsApp no llegará a leerlo"
fi

# ---------- og:image ----------
echo; echo "og:image:"
img=$(meta og:image)
if [[ -z "$img" ]]; then
  bad "falta og:image — sin ella no hay preview con logo en ningún cliente"
else
  case "$img" in
    https://*) ok "URL absoluta https: $img" ;;
    http://*)  bad "$img es http:// — WhatsApp/Facebook exigen https" ;;
    *)         bad "'$img' es relativa — Facebook, WhatsApp y LinkedIn la ignoran; debe ser absoluta" ;;
  esac
  if [[ "$img" == http* ]]; then
    read -r icode ctype ibytes <<< "$("${CURL[@]}" -o "$IMG" -w '%{http_code} %{content_type} %{size_download}' "$img")"
    [[ "$icode" == "200" ]] && ok "HTTP $icode" || bad "HTTP $icode al pedir la imagen"
    [[ "$ctype" == image/* ]] && ok "content-type $ctype" || bad "content-type '$ctype' — debe ser image/* (¿SPA devolviendo index.html?)"
    if (( ibytes <= 300000 )); then ok "$(( ibytes / 1024 )) KB"
    else warn "$(( ibytes / 1024 )) KB > 300 KB — WhatsApp puede no mostrarla; regenera como jpg"; fi
    dims=$( { magick identify -format '%wx%h' "$IMG" 2>/dev/null || identify -format '%wx%h' "$IMG" 2>/dev/null; } || true)
    if [[ -n "$dims" ]]; then
      w=${dims%x*}; h=${dims#*x}
      if (( w >= 1200 && h >= 600 )); then ok "dimensiones $dims"
      elif (( w >= 600 && h >= 315 )); then warn "dimensiones $dims — funciona, pero 1200x630 se ve nítida en todos"
      else bad "dimensiones $dims — demasiado pequeña; Facebook exige ≥ 200x200 y sólo da tarjeta grande a partir de 600x315"; fi
    fi
  fi
  w=$(meta og:image:width); h=$(meta og:image:height)
  [[ -n "$w" && -n "$h" ]] && ok "og:image:width/height declarados (${w}x${h})" || warn "sin og:image:width/height — Facebook tarda un scrape más en mostrar la imagen la primera vez"
fi

# ---------- favicon e iconos ----------
echo; echo "Favicon e iconos:"
check_asset() { # etiqueta url
  local r; r=$("${CURL[@]}" -o /dev/null -w '%{http_code} %{content_type}' "$2")
  case "$r" in
    200\ image/*) ok "$1 → $2 ($r)" ;;
    200\ *)       bad "$1 → $2 responde 200 pero con '${r#200 }' — es un 404 disfrazado (catch-all de la app)" ;;
    *)            bad "$1 → $2 ($r)" ;;
  esac
}
ico=$(link_href icon); [[ -z "$ico" ]] && ico=$(link_href 'shortcut icon')
if [[ -n "$ico" ]]; then check_asset '<link rel="icon">' "$(abs "$ico")"
else warn 'sin <link rel="icon">; los navegadores buscarán /favicon.ico a ciegas'; fi
check_asset "/favicon.ico" "$origin/favicon.ico"

apple=$(link_href apple-touch-icon)
if [[ -n "$apple" ]]; then check_asset 'apple-touch-icon' "$(abs "$apple")"
else warn 'sin apple-touch-icon — iOS usará una captura de la página al "Añadir a inicio"'; fi

man=$(link_href manifest)
if [[ -n "$man" ]]; then
  r=$("${CURL[@]}" -o /dev/null -w '%{http_code}' "$(abs "$man")")
  [[ "$r" == "200" ]] && ok "manifest → $(abs "$man")" || bad "manifest → $(abs "$man") (HTTP $r)"
else warn 'sin <link rel="manifest"> (sólo importa para PWA / "Añadir a inicio" en Android)'; fi

theme=$(meta theme-color)
[[ -n "$theme" ]] && ok "theme-color $theme" || warn "sin theme-color (colorea la barra en móvil y el borde del embed en Discord)"

# ---------- resultado ----------
echo
if (( fail )); then
  echo "Resultado: hay fallos. Síntoma → causa en references/gotchas.md"
  exit 1
fi
echo "Resultado: OK. Prueba real: mándate el link por WhatsApp y pásalo por"
echo "  https://developers.facebook.com/tools/debug/  ·  https://www.linkedin.com/post-inspector/"
