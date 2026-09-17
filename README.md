# skills

Agent skills propios, instalables en Claude Code y otros agentes compatibles.

## Instalación

```bash
npx skills add Cachiss/skills
```

O un skill concreto:

```bash
npx skills add Cachiss/skills/laravel-dokploy
```

## Skills

| Skill | Para qué sirve |
|---|---|
| [`laravel-dokploy`](skills/laravel-dokploy) | Dockerizar proyectos Laravel (incl. Filament) y desplegarlos en Dokploy detrás de Traefik, con contenedores opcionales de BD, Redis o almacenamiento. Incluye diagnóstico de despliegues rotos. |
| [`dev-basics`](skills/dev-basics) | Básicos de todo proyecto web nuevo: logo como favicon + metatags + Open Graph para que salga al compartir el link (con scripts que generan los iconos y verifican la URL como el crawler de WhatsApp); validación de teléfonos con libphonenumber y limpieza de formatos viejos de México, guardados en E.164; y ojo de mostrar/ocultar en todo input de contraseña (Blade/Alpine, React, Vue, vanilla, Filament). |

## Estructura

```
skills/
└── <nombre-del-skill>/
    ├── SKILL.md          # instrucciones (frontmatter: name + description)
    ├── references/       # detalle que se carga bajo demanda
    ├── templates/        # archivos para copiar al proyecto
    └── scripts/          # opcional: herramientas que el agente ejecuta
```

El `description` del frontmatter es lo que decide si el agente carga el skill: describe **cuándo**
usarlo, no sólo qué hace.

## Desarrollo local

Para probar un skill sin publicarlo:

```bash
ln -s "$PWD/skills/laravel-dokploy" ~/.claude/skills/laravel-dokploy
```
