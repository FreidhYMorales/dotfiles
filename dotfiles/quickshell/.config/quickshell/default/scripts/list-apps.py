#!/usr/bin/env python3
import glob, os, configparser, json, re

ICON_BASES   = ['/usr/share/icons', os.path.expanduser('~/.local/share/icons')]
# is_mono: theme ships fill:currentColor SVGs with no color of its own — the
# launcher recolors these live (AppItem.qml MultiEffect) instead of trusting
# a baked-in hue, so an icon can track selection state like everything else.
ICON_THEMES  = [
    ('yamis-mono',   True),
    ('hicolor',      False),
    ('Papirus',      False),
    ('Papirus-Dark', False),
    ('breeze',       False),
    ('breeze-dark',  False),
    ('Adwaita',      False),
    ('gnome',        False),
]
ICON_SIZES   = ['256x256', '128x128', '64x64', '48x48', '32x32', 'scalable']
ICON_CATS    = ['apps', 'applications', '']

def find_icon(name):
    if not name:
        return '', False
    if os.path.isabs(name) and os.path.exists(name):
        return name, False
    # Theme outer, base inner: yamis-mono (~/.local/share/icons) must outrank
    # hicolor/Papirus (/usr/share/icons) even though it sits in the "lower"
    # base dir — looping base-outer would exhaust every theme under
    # /usr/share/icons before ever checking ~/.local/share/icons.
    for theme, is_mono in ICON_THEMES:
        for base in ICON_BASES:
            for size in ICON_SIZES:
                for cat in ICON_CATS:
                    for ext in ['png', 'svg']:
                        # Papirus/Adwaita/hicolor nest size then category
                        # (scalable/apps); breeze/yamis nest category then
                        # size instead (apps/scalable) — try both.
                        for parts in (
                            [base, theme, size] + ([cat] if cat else []),
                            [base, theme] + ([cat] if cat else []) + [size],
                        ):
                            path = os.path.join(*parts, f'{name}.{ext}')
                            if os.path.exists(path):
                                return path, is_mono
    for ext in ['png', 'svg', 'xpm']:
        path = f'/usr/share/pixmaps/{name}.{ext}'
        if os.path.exists(path):
            return path, False
    return '', False

apps = []
seen = set()

paths = sorted(
    glob.glob('/usr/share/applications/*.desktop') +
    glob.glob(os.path.expanduser('~/.local/share/applications/*.desktop')),
    key=lambda p: os.path.basename(p).lower()
)

for path in paths:
    try:
        p = configparser.ConfigParser(interpolation=None)
        p.read(path, encoding='utf-8')
        if 'Desktop Entry' not in p:
            continue
        s = p['Desktop Entry']
        if s.get('Type', '') != 'Application':
            continue
        if s.get('NoDisplay', '').lower() == 'true':
            continue
        name     = s.get('Name', '').strip()
        exec_cmd = re.sub(r'\s*%[A-Za-z]\s*', ' ', s.get('Exec', '')).strip()
        if not name or not exec_cmd or name in seen:
            continue
        seen.add(name)
        desc = (s.get('GenericName', '') or s.get('Comment', '')).strip()
        icon_path, icon_mono = find_icon(s.get('Icon', ''))
        apps.append({'name': name, 'exec': exec_cmd, 'icon': icon_path, 'iconMono': icon_mono, 'description': desc})
    except Exception:
        pass

apps.sort(key=lambda a: a['name'].lower())
print(json.dumps(apps))
