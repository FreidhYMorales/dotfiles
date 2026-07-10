#!/usr/bin/env python3
import glob, os, configparser, json, re

ICON_BASES   = ['/usr/share/icons', os.path.expanduser('~/.local/share/icons')]
ICON_THEMES  = ['hicolor', 'Papirus', 'Papirus-Dark', 'breeze', 'breeze-dark', 'Adwaita', 'gnome']
ICON_SIZES   = ['256x256', '128x128', '64x64', '48x48', '32x32', 'scalable/apps', 'scalable']
ICON_CATS    = ['apps', 'applications', '']

def find_icon(name):
    if not name:
        return ''
    if os.path.isabs(name) and os.path.exists(name):
        return name
    for base in ICON_BASES:
        for theme in ICON_THEMES:
            for size in ICON_SIZES:
                for cat in ICON_CATS:
                    for ext in ['png', 'svg']:
                        parts = [base, theme, size] + ([cat] if cat else []) + [f'{name}.{ext}']
                        path = os.path.join(*parts)
                        if os.path.exists(path):
                            return path
    for ext in ['png', 'svg', 'xpm']:
        path = f'/usr/share/pixmaps/{name}.{ext}'
        if os.path.exists(path):
            return path
    return ''

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
        apps.append({'name': name, 'exec': exec_cmd, 'icon': find_icon(s.get('Icon', '')), 'description': desc})
    except Exception:
        pass

apps.sort(key=lambda a: a['name'].lower())
print(json.dumps(apps))
