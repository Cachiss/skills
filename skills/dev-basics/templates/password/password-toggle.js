/*
  password-toggle.js — añade el ojo de mostrar/ocultar a TODOS los <input type="password"> de la
  página, incluidos los que aparezcan después (modales, Livewire, fetch de formularios).

  Uso:      <script src="/js/password-toggle.js" defer></script>
  Excluir:  <input type="password" data-no-toggle>
  Estilos:  hereda el color del input (currentColor). Ajusta .pw-toggle en tu CSS si hace falta.

  Cuándo NO usarlo: si controlas el markup (React, Vue, Blade con Alpine, Filament), usa el
  componente del stack: es más limpio que envolver inputs desde fuera. Este script es para HTML
  plano, plantillas heredadas o cuando hay decenas de formularios que no vas a tocar uno a uno.
*/
(() => {
  const ICON_EYE =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
    '<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>';
  const ICON_EYE_OFF =
    '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' +
    '<path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 10 8 10 8a13.16 13.16 0 0 1-1.67 2.68"/>' +
    '<path d="M6.61 6.61A13.5 13.5 0 0 0 2 12s3 8 10 8a9.74 9.74 0 0 0 5.39-1.61"/>' +
    '<path d="M14.12 14.12a3 3 0 1 1-4.24-4.24"/><path d="M2 2l20 20"/></svg>';

  const CSS =
    '.pw-field{position:relative}' +
    '.pw-field>input{padding-right:2.75rem!important;width:100%;box-sizing:border-box}' +
    '.pw-toggle{position:absolute;top:50%;right:.375rem;transform:translateY(-50%);width:2rem;height:2rem;' +
    'display:inline-flex;align-items:center;justify-content:center;margin:0;padding:0;border:0;background:none;' +
    'color:inherit;opacity:.6;cursor:pointer;border-radius:.375rem}' +
    '.pw-toggle:hover,.pw-toggle:focus-visible{opacity:1}' +
    '.pw-toggle:focus-visible{outline:2px solid currentColor;outline-offset:2px}' +
    '.pw-toggle svg{width:1.25rem;height:1.25rem}';

  const LABEL_SHOW = 'Mostrar contraseña';
  const LABEL_HIDE = 'Ocultar contraseña';

  function injectCss() {
    if (document.querySelector('style[data-pw-toggle]')) return;
    const style = document.createElement('style');
    style.setAttribute('data-pw-toggle', '');
    style.textContent = CSS;
    document.head.appendChild(style);
  }

  function enhance(input) {
    if (input.dataset.pwEnhanced || input.hasAttribute('data-no-toggle')) return;
    if (input.closest('.pw-field')) return;
    input.dataset.pwEnhanced = '1';

    // Al mostrarla como texto, el móvil intentaría autocorregir/capitalizar
    input.setAttribute('autocapitalize', 'off');
    input.setAttribute('autocorrect', 'off');
    input.setAttribute('spellcheck', 'false');

    // El wrapper ocupa el sitio del input: copia lo que define su tamaño en el layout
    const cs = getComputedStyle(input);
    const parentCs = input.parentElement ? getComputedStyle(input.parentElement) : null;
    const wrapper = document.createElement('div');
    wrapper.className = 'pw-field';
    wrapper.style.display = cs.display === 'block' ? 'block' : 'inline-block';
    if (cs.display !== 'block') wrapper.style.width = cs.width;
    if (parentCs && /flex/.test(parentCs.display)) wrapper.style.flex = cs.flex;
    if (parentCs && /grid/.test(parentCs.display)) wrapper.style.gridColumn = cs.gridColumn;
    wrapper.style.verticalAlign = cs.verticalAlign;

    const btn = document.createElement('button');
    btn.type = 'button';               // nunca submit
    btn.className = 'pw-toggle';
    btn.setAttribute('aria-label', LABEL_SHOW);
    btn.setAttribute('aria-pressed', 'false');
    btn.innerHTML = ICON_EYE;

    btn.addEventListener('click', () => {
      const show = input.type === 'password';
      const { selectionStart, selectionEnd } = input;
      input.type = show ? 'text' : 'password';
      try { input.setSelectionRange(selectionStart, selectionEnd); } catch (_) { /* no en todos los navegadores */ }
      btn.innerHTML = show ? ICON_EYE_OFF : ICON_EYE;
      btn.setAttribute('aria-label', show ? LABEL_HIDE : LABEL_SHOW);
      btn.setAttribute('aria-pressed', String(show));
    });

    input.parentNode.insertBefore(wrapper, input);
    wrapper.appendChild(input);
    wrapper.appendChild(btn);
  }

  function enhanceAll(root) {
    if (root.nodeType !== 1 && root.nodeType !== 9) return;
    if (root.matches && root.matches('input[type="password"]')) enhance(root);
    root.querySelectorAll('input[type="password"]').forEach(enhance);
  }

  function init() {
    injectCss();
    enhanceAll(document);
    new MutationObserver((mutations) => {
      for (const m of mutations) m.addedNodes.forEach(enhanceAll);
    }).observe(document.documentElement, { childList: true, subtree: true });
  }

  document.readyState === 'loading' ? document.addEventListener('DOMContentLoaded', init) : init();
})();
