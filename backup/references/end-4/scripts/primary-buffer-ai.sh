#!/bin/bash
# Mandar selección primaria de Wayland a Ollama local — end-4/dots-hyprland
# Seleccionás texto en cualquier app (sin Ctrl+C), apretás el keybind,
# y te llega una notificación con la respuesta del LLM.
#
# - Si el texto tiene <= 30 chars: usa el texto como título de la notificación
# - Si es más largo: título genérico "AI Response"
# - Detecta automáticamente el primer modelo cargado en Ollama
#
# Deps: ollama, wl-clipboard (wl-paste -p), curl, jq, notify-send
# Hyprland binding: bind = SUPER ALT, Q, exec, primary-buffer-ai

SYSTEM_PROMPT="You are a helpful, quick assistant that provides brief and concise explanation \
to given content in at most 100 characters. If the given content is not in English, translate \
it to English. If the content is an English word, provide its meaning. If the content is a name, \
provide some info about it. For a math expression, provide a simplification, \
each step on a line following this style: \`2x=11 (subtract 7 from both sides)\`. \
If you do not know the answer, simply say 'No info available'. \
Only respond for the appropriate case and use as little text as possible. The content:"

# Detectar el primer modelo cargado en Ollama
first_loaded=$(curl -s http://localhost:11434/api/ps 2>/dev/null | jq -r '.models[0].model' 2>/dev/null)
model="${first_loaded:-llama3.2}"

while [[ "$#" -gt 0 ]]; do
    case $1 in --model) model="$2"; shift ;; esac
    shift
done

content=$(wl-paste -p | tr '\n' ' ' | head -c 2000)
[[ -z "$content" ]] && exit 0

prompt_json=$(jq -n --arg s "$SYSTEM_PROMPT" --arg c "$content" '$s + " " + $c')
api_payload=$(jq -n --arg model "$model" --argjson prompt "$prompt_json" --argjson stream false \
    '{model: $model, prompt: $prompt, stream: $stream}')
response=$(curl -s http://localhost:11434/api/generate -d "$api_payload" | jq -r '.response' 2>/dev/null)

if [[ ${#content} -le 30 && "$content" != *$'\n'* ]]; then
    notify-send --app-name="AI" --expire-time=10000 "$content" "$response"
else
    notify-send --app-name="AI" --expire-time=10000 "AI Response" "$response"
fi
