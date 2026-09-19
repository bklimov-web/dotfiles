# Расшифровка аудио (whispermlx). HF-токен берётся из macOS Keychain (service: hf_token).

run_transcribe() {
  local input_file="$1"
  if [[ -z "$input_file" ]]; then
    echo "Использование: run_transcribe путь/к/записи.m4a"
    return 1
  fi

  local root=~/Desktop/memos
  local base="$(basename "$input_file" | sed 's/\.[^.]*$//')"

  source ~/whispermlx-env/bin/activate
  export HF_TOKEN=$(security find-generic-password -a "$USER" -s hf_token -w)
  export HF_HUB_DISABLE_XET=1
  export HF_HUB_DOWNLOAD_TIMEOUT=300

  python3 -c "
  from huggingface_hub import snapshot_download
  snapshot_download('mlx-community/whisper-large-v3-mlx')
  print('Готово')
  "

  whispermlx "$input_file" \
    --model large-v3 \
    --diarize \
    --min_speakers 2 --max_speakers 3 \
    --hf_token "$HF_TOKEN" \
    --output_format srt \
    --output_dir "$root/transcripts"

  deactivate

  python3 "$root/scripts/srt_to_llm.py" "$root/transcripts/$base.srt"

  # srt_to_llm.py у тебя сейчас кладёт .txt рядом со .srt — переносим в final/
  if [[ -f "$root/transcripts/${base}_clean.txt" ]]; then
    mv "$root/transcripts/${base}_clean.txt" "$root/final/$base.txt"
    echo "✅ Готово: $root/final/$base.txt"
  else
    echo "⚠️  Не нашёл $root/transcripts/${base}_clean.txt — проверь, куда именно srt_to_llm.py сохраняет результат"
  fi
}
