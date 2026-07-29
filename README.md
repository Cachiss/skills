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

## Estructura

```
skills/
└── <nombre-del-skill>/
    ├── SKILL.md          # instrucciones (frontmatter: name + description)
    ├── references/       # detalle que se carga bajo demanda
    └── templates/        # archivos para copiar al proyecto
```

El `description` del frontmatter es lo que decide si el agente carga el skill: describe **cuándo**
usarlo, no sólo qué hace.

## Desarrollo local

Para probar un skill sin publicarlo:

```bash
ln -s "$PWD/skills/laravel-dokploy" ~/.claude/skills/laravel-dokploy
```
